.PHONY: all build install uninstall run clean help

APP_NAME    := SpeechRecog
BUILD_DIR   := build
APP_BUNDLE  := $(BUILD_DIR)/$(APP_NAME).app
INSTALL_DIR ?= /Applications

all: build

help:
	@echo "SpeechRecog · targets disponibles"
	@echo ""
	@echo "  make build      → compila $(APP_BUNDLE)"
	@echo "  make install    → compila y copia la .app a $(INSTALL_DIR)/"
	@echo "                    (override: make install INSTALL_DIR=~/Applications)"
	@echo "  make uninstall  → elimina $(INSTALL_DIR)/$(APP_NAME).app"
	@echo "  make run        → compila y abre la .app desde ./build"
	@echo "  make clean      → borra build/, .build/ y .swiftpm/"
	@echo ""
	@echo "Variables:"
	@echo "  CODESIGN_IDENTITY  identidad para firmar (por defecto: ad-hoc '-')"
	@echo "                     ej.: CODESIGN_IDENTITY=\"Developer ID Application: …\" make install"

build:
	@./scripts/build-app.sh

install: build
	@pkill -f "$(APP_NAME).app/Contents/MacOS/$(APP_NAME)" 2>/dev/null || true
	@sleep 0.5
	@if [ ! -d "$(INSTALL_DIR)" ]; then \
		echo "✗ $(INSTALL_DIR) no existe"; exit 1; \
	fi
	@echo "→ Instalando en $(INSTALL_DIR)/"
	@if ! rm -rf "$(INSTALL_DIR)/$(APP_NAME).app" 2>/dev/null; then \
		echo "  (probando con sudo)"; \
		sudo rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"; \
	fi
	@if ! cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/" 2>/dev/null; then \
		echo "  (probando con sudo)"; \
		sudo cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/"; \
	fi
	@echo "✓ Instalado: $(INSTALL_DIR)/$(APP_NAME).app"
	@echo ""
	@echo "  Abrir:        open '$(INSTALL_DIR)/$(APP_NAME).app'"
	@echo "  La primera vez macOS pedirá permiso para grabar audio del sistema."

uninstall:
	@if [ -d "$(INSTALL_DIR)/$(APP_NAME).app" ]; then \
		if ! rm -rf "$(INSTALL_DIR)/$(APP_NAME).app" 2>/dev/null; then \
			sudo rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"; \
		fi; \
		echo "✓ Eliminado: $(INSTALL_DIR)/$(APP_NAME).app"; \
	else \
		echo "· No hay nada que eliminar en $(INSTALL_DIR)/"; \
	fi

run: build
	@open "$(APP_BUNDLE)"

clean:
	@rm -rf $(BUILD_DIR) .build .swiftpm
	@echo "✓ Limpieza completa"
