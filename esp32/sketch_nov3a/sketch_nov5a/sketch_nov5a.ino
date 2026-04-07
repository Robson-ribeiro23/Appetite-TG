#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <time.h>
#include <vector>

// --- 1. CONFIGURAÇÃO DA REDE  
const char* SSID_FIXO = "appt";  // <--- COLOQUE O NOME EXATO
const char* SENHA_FIXA = "mkiujn12"; // <--- COLOQUE A SENHA EXATA

// --- HARDWARE ---
const int MOTOR_PIN = 23;

// --- VARIÁVEIS GLOBAIS ---
WebServer server(80); // Cria o servidor na porta 80 (HTTP Padrão)
bool motorIsRunning = false;
unsigned long motorStopTime = 0;

// Estrutura para guardar os alarmes
struct Alarm {
    int hour;
    int minute;
    double grams;
};
std::vector<Alarm> alarms; // Lista dinâmica de alarmes

// --- RELÓGIO (NTP) ---
const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = -10800; // GMT-3 (Brasil)
const int   daylightOffset_sec = 0;

// --- FUNÇÃO PARA LIGAR O MOTOR ---
void activateMotor(double grams) {
    if(!motorIsRunning) {
        // Calibração: 250ms por grama
        long duration = (long)(grams * 250); 
        
        motorIsRunning = true;
        motorStopTime = millis() + duration;
        digitalWrite(MOTOR_PIN, HIGH);
        
        Serial.printf("MOTOR LIGADO: %.1fg por %ldms\n", grams, duration);
    }
}

void setup() {
  Serial.begin(115200);
  pinMode(MOTOR_PIN, OUTPUT);
  digitalWrite(MOTOR_PIN, LOW);

  // 1. Conecta no Wi-Fi (Hotspot)
  Serial.println("\n--- INICIANDO MODO APRESENTAÇÃO (HTTP) ---");
  Serial.printf("Tentando conectar em: %s\n", SSID_FIXO);
  
  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID_FIXO, SENHA_FIXA);

  // Espera conectar
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("\n\nWiFi CONECTADO!");
  Serial.println("------------------------------------------------");
  Serial.print("IP DO ESP32 PARA O FLUTTER: ");
  Serial.println(WiFi.localIP()); // <--- ANOTE ESTE NÚMERO!!!
  Serial.println("------------------------------------------------");

  // 2. Inicia o Relógio
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

  // 3. Define as Rotas (O que o Flutter vai chamar)

  // Rota de Teste (Ping)
  server.on("/status", HTTP_GET, []() {
    server.send(200, "application/json", "{\"status\":\"online\"}");
    Serial.println("Ping recebido do App.");
  });

  // Rota Manual (Alimentar Agora)
  server.on("/manual", HTTP_POST, []() {
    if (!server.hasArg("plain")) {
      server.send(400, "application/json", "{\"error\":\"Sem dados\"}");
      return;
    }
    
    DynamicJsonDocument doc(512);
    deserializeJson(doc, server.arg("plain"));
    
    if(doc.containsKey("grams")) {
        double grams = doc["grams"];
        activateMotor(grams);
        server.send(200, "application/json", "{\"success\":true}");
    } else {
        server.send(400, "application/json", "{\"error\":\"Falta grams\"}");
    }
  });

  // Rota de Alarmes (Receber Lista)
  server.on("/alarms", HTTP_POST, []() {
      if (server.hasArg("plain")) {
          DynamicJsonDocument doc(2048);
          deserializeJson(doc, server.arg("plain"));
          JsonArray arr = doc.as<JsonArray>();
          
          alarms.clear();
          for (JsonObject v : arr) {
              Alarm a;
              a.hour = v["hour"];
              a.minute = v["minute"];
              a.grams = v["grams"];
              alarms.push_back(a);
              Serial.printf("Alarme salvo: %02d:%02d - %.1fg\n", a.hour, a.minute, a.grams);
          }
          server.send(200, "application/json", "{\"success\":true}");
      }
  });

  server.begin();
  Serial.println("Servidor HTTP iniciado.");
}

void loop() {
  // Mantém o servidor ouvindo
  server.handleClient();

  // 1. Lógica do Motor (Desligar quando acabar o tempo)
  if (motorIsRunning && millis() >= motorStopTime) {
    digitalWrite(MOTOR_PIN, LOW);
    motorIsRunning = false;
    Serial.println("Motor desligado.");
  }

  // 2. Lógica de Alarmes (Checar a cada minuto)
  static int lastMin = -1;
  struct tm timeinfo;
  
  if (getLocalTime(&timeinfo)) {
      // Só verifica se o minuto mudou (para não disparar 1000 vezes no mesmo minuto)
      if (timeinfo.tm_min != lastMin) {
          lastMin = timeinfo.tm_min;
          
          Serial.printf("Relógio: %02d:%02d\n", timeinfo.tm_hour, timeinfo.tm_min);
          
          for(auto &a : alarms) {
              if(a.hour == timeinfo.tm_hour && a.minute == timeinfo.tm_min) {
                  Serial.println("ALARME ACIONADO!");
                  activateMotor(a.grams);
              }
          }
      }
  }
}