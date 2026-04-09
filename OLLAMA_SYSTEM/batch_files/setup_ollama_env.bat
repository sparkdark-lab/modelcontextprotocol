@echo off
REM Ollama Environment Setup
REM Sets OLLAMA_MODELS environment variable to point to OLLAMA_SYSTEM/models

set OLLAMA_MODELS=E:\AI_Tools\Central_Repository\OLLAMA_SYSTEM\models
echo OLLAMA_MODELS set to: %OLLAMA_MODELS%

REM Start Ollama with the new models directory
echo.
echo Starting Ollama...
"%LOCALAPPDATA%\Programs\Ollama\ollama.exe" serve

