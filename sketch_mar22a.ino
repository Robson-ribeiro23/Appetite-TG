  #include <WiFi.h>
  #include <WiFiClientSecure.h>
  #include <PubSubClient.h>
  #include <ArduinoJson.h>
  #include <time.h>
  #include <vector>
  #include <WebServer.h>
  #include <Preferences.h>

  // Protótipo antecipado para o Arduino IDE
  void callback(char*, byte*, unsigned int);

  // --- CONFIGURAÇÃO DO HIVEMQ CLOUD ---
  const char* mqtt_server = "a5be7b04667949908ba52635028c884d.s1.eu.hivemq.cloud";
  const int mqtt_port = 8883;
  const char* mqtt_user = "appetite_admin";
  const char* mqtt_pass = "Mkiujn123";
  const char* mqtt_client_id = "esp32_appetite_hardware";

  // --- TÓPICOS MQTT ---
  const char* topic_manual = "appetite/device/alimentador_01/command/manual";
  const char* topic_alarms = "appetite/device/alimentador_01/command/alarms";
  const char* topic_status = "appetite/device/alimentador_01/status";

  // --- OBJETOS GLOBAIS ---
  const int MOTOR_PIN = 23;
  WiFiClientSecure espClient;
  PubSubClient client(espClient);
  WebServer server(80);
  Preferences preferences;

  // Variáveis de Estado
  bool motorIsRunning = false;
  unsigned long motorStopTime = 0;
  bool isProvisioningMode = false;

  // Flags para ações pendentes (evita publish direto dentro do callback)
  bool pendingStatusPublish = false;
  String pendingStatusPayload = "";

  struct Alarm {
      int hour;
      int minute;
      double grams;
  };
  std::vector<Alarm> alarms;

  const char* ntpServer = "pool.ntp.org";
  const long  gmtOffset_sec = -10800; // GMT-3
  const int   daylightOffset_sec = 0;

  // ==========================================
  // FUNÇÕES DE PROVISIONAMENTO (Wi-Fi Manager)
  // ==========================================

  void startProvisioning() {
    isProvisioningMode = true;
    Serial.println("\n--- MODO PROVISIONAMENTO INICIADO ---");

    WiFi.mode(WIFI_AP);
    WiFi.softAP("Appetite_SETUP");
    Serial.print("Conecte-se a rede Appetite_SETUP e acesse IP: ");
    Serial.println(WiFi.softAPIP());

    server.on("/config", HTTP_POST, []() {
      if (server.hasArg("ssid") && server.hasArg("password")) {
        String newSSID = server.arg("ssid");
        String newPass = server.arg("password");

        Serial.println("Credenciais recebidas do App!");

        preferences.begin("wifi_config", false);
        preferences.putString("ssid", newSSID);
        preferences.putString("password", newPass);
        preferences.end();

        server.send(200, "text/plain", "Credenciais recebidas. Reiniciando...");

        delay(2000);
        ESP.restart();
      } else {
        server.send(400, "text/plain", "Erro: Faltam credenciais");
      }
    });

    server.begin();
  }

  // ==========================================
  // LÓGICA DO ALIMENTADOR (Modo Normal)
  // ==========================================

  // Enfileira publicação para ser feita no loop principal
  void queueStatusPublish(String payload) {
      pendingStatusPublish = true;
      pendingStatusPayload = payload;
  }

  void activateMotor(double grams) {
      if(!motorIsRunning) {
          long duration = (long)(grams * 250);
          motorIsRunning = true;
          motorStopTime = millis() + duration;
          digitalWrite(MOTOR_PIN, HIGH);
          Serial.printf("MOTOR LIGADO: %.1fg por %ldms\n", grams, duration);
          queueStatusPublish("{\"status\":\"alimentando\"}");
      } else {
          Serial.println("MOTOR OCUPADO - comando ignorado");
      }
  }

  void callback(char* topic, byte* payload, unsigned int length) {
    String message = "";
    for (int i = 0; i < length; i++) message += (char)payload[i];

    Serial.printf("[MQTT] topic=[%s] len=%d msg=[%s]\n", topic, length, message.c_str());

    if (String(topic) == topic_manual) {
        DynamicJsonDocument doc(512);
        DeserializationError error = deserializeJson(doc, message);

        if (error) {
            Serial.printf("[MQTT] JSON parse error: %s\n", error.c_str());
            return;
        }

        if (doc.containsKey("grams")) {
            Serial.println("[MQTT] Comando de GRAMS detectado -> acionando motor");
            activateMotor(doc["grams"]);
        }
        else if (doc.containsKey("ping")) {
            Serial.println("[MQTT] PING detectado -> respondendo online");
            queueStatusPublish("{\"status\":\"online\"}");
        }
        else {
            Serial.println("[MQTT] Comando manual nao reconhecido (sem grams nem ping)");
        }
    }
    else if (String(topic) == topic_alarms) {
        DynamicJsonDocument doc(2048);
        DeserializationError error = deserializeJson(doc, message);
        if (error) {
            Serial.printf("[MQTT] JSON parse error (alarms): %s\n", error.c_str());
            return;
        }
        JsonArray arr = doc.as<JsonArray>();
        alarms.clear();
        for (JsonObject v : arr) {
            Alarm a;
            a.hour = v["hour"]; a.minute = v["minute"]; a.grams = v["grams"];
            alarms.push_back(a);
        }
        Serial.printf("[MQTT] %d alarmes atualizados\n", alarms.size());
        queueStatusPublish("{\"status\":\"alarmes_atualizados\"}");
    }
  }

  void reconnectMQTT() {
    if (!client.connected()) {
      Serial.print("Tentando ligar MQTT...");
      if (client.connect(mqtt_client_id, mqtt_user, mqtt_pass)) {
        Serial.println("LIGADO!");
        client.subscribe(topic_manual, 1);
        client.subscribe(topic_alarms, 1);
        queueStatusPublish("{\"status\":\"online\"}");
        for(int i = 0; i < 5; i++) {
          client.loop();
          delay(50);
        }
        Serial.println("[MQTT] Subscriptions confirmadas");
      } else {
        Serial.print("Falhou (rc=");
        Serial.print(client.state());
        Serial.println("). Tentando novamente em 5s...");
      }
    }
  }

  // Processa publishes pendentes (chamado apenas no loop principal)
  void processPendingPublishes() {
      if (pendingStatusPublish && client.connected()) {
          client.publish(topic_status, pendingStatusPayload.c_str());
          Serial.printf("[MQTT] Status publicado: %s\n", pendingStatusPayload.c_str());
          pendingStatusPublish = false;
          pendingStatusPayload = "";
      }
  }

  // ==========================================
  // SETUP PRINCIPAL
  // ==========================================

  void setup() {
    Serial.begin(115200);
    pinMode(MOTOR_PIN, OUTPUT);
    digitalWrite(MOTOR_PIN, LOW);

    preferences.begin("wifi_config", true);
    String savedSSID = preferences.getString("ssid", "");
    String savedPass = preferences.getString("password", "");
    preferences.end();

    if (savedSSID != "") {
      Serial.printf("\nTentando conectar a rede salva: %s\n", savedSSID.c_str());
      WiFi.mode(WIFI_STA);
      WiFi.begin(savedSSID.c_str(), savedPass.c_str());

      int attempts = 0;
      while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
      }
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nWiFi CONECTADO com Sucesso!");
      isProvisioningMode = false;

      espClient.setInsecure();
      configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
      client.setServer(mqtt_server, mqtt_port);
      client.setCallback(callback);

    } else {
      Serial.println("\nFalha no Wi-Fi. Alternando para Modo Provisionamento.");
      startProvisioning();
    }
  }

  void loop() {
    if (isProvisioningMode) {
      server.handleClient();
      return;
    }

    static unsigned long lastReconnectAttempt = 0;

    if (WiFi.status() != WL_CONNECTED) {
        unsigned long now = millis();
        if (now - lastReconnectAttempt > 5000) {
            lastReconnectAttempt = now;
            Serial.println("[WiFi] Reconectando...");
            WiFi.reconnect();
        }
        return;
    }

    if (!client.connected()) {
      unsigned long now = millis();
      if (now - lastReconnectAttempt > 5000) {
        lastReconnectAttempt = now;
        reconnectMQTT();
      }
    } else {
      client.loop();
    }

    // Publicações pendentes feitas FORA do callback
    processPendingPublishes();

    if (motorIsRunning && millis() >= motorStopTime) {
      digitalWrite(MOTOR_PIN, LOW);
      motorIsRunning = false;
      Serial.println("Motor desligado.");
      queueStatusPublish("{\"status\":\"sucesso_alimentacao\"}");
    }

    static int lastMin = -1;
    struct tm timeinfo;
    if (getLocalTime(&timeinfo) && timeinfo.tm_min != lastMin) {
        lastMin = timeinfo.tm_min;
        for(auto &a : alarms) {
            if(a.hour == timeinfo.tm_hour && a.minute == timeinfo.tm_min) {
                Serial.println("ALARME ACIONADO PELA ROTINA!");
                activateMotor(a.grams);
            }
        }
    }
  }