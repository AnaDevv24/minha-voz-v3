@echo off
setlocal EnableDelayedExpansion
title Minha Voz - atualizar um repositorio do GitHub
cd /d "%~dp0"
set LISTA=repositorios-github.txt

where git >nul 2>nul || (echo Falta instalar o Git: https://git-scm.com & pause & exit /b 1)

git config user.name >nul 2>nul && goto :temEmail
set /p NOME=Seu usuario do GitHub: 
git config --global user.name "!NOME!"
:temEmail
git config user.email >nul 2>nul && goto :lista
set /p EMAIL=Seu e-mail do GitHub: 
git config --global user.email "!EMAIL!"

:lista
if not exist .git git init -q
if not exist %LISTA% echo https://github.com/AnaDevv24/minha-voz.git> %LISTA%

echo ==============================================
echo   Qual repositorio voce quer atualizar?
echo ==============================================
set N=0
for /f "usebackq delims=" %%r in ("%LISTA%") do (
  set /a N+=1
  set REPO!N!=%%r
  echo   !N! - %%r
)
echo   A - adicionar outro repositorio a lista
echo.
set ESCOLHA=1
set /p ESCOLHA=Digite o numero (Enter = 1): 
if /i "!ESCOLHA!"=="A" goto :adicionar
set URL=!REPO%ESCOLHA%!
if "!URL!"=="" (echo Opcao invalida. & pause & exit /b 1)
goto :enviar

:adicionar
set NOVO=
set /p NOVO=Cole o endereco do repositorio (termina em .git): 
if "!NOVO!"=="" (echo Nenhum endereco informado. & pause & exit /b 1)
echo !NOVO!>> %LISTA%
set URL=!NOVO!

:enviar
echo.
echo Repositorio: !URL!
set BASE=
git fetch -q "!URL!" main >nul 2>nul && set BASE=FETCH_HEAD

rem Monta a versao em um indice separado: a pasta e o historico local nao mudam.
set GIT_INDEX_FILE=%TEMP%\minhavoz-indice-%RANDOM%%RANDOM%
if defined BASE (git read-tree FETCH_HEAD) else (git read-tree --empty)
git add -A
for /f %%t in ('git write-tree') do set ARVORE=%%t

if not defined BASE goto :mudancas
for /f %%t in ('git log -1 --format^=%%T FETCH_HEAD') do set ANTIGA=%%t
if "!ARVORE!"=="!ANTIGA!" (
  echo.
  echo Nada mudou desde a ultima versao enviada para este repositorio.
  goto :fim
)
echo.
echo O que mudou:
git diff-index --cached --name-status FETCH_HEAD

:mudancas
echo.
set MSG=Atualizacao do Minha Voz
set /p MSG=Descreva o que mudou (ou so Enter): 
if defined BASE (
  for /f %%c in ('git commit-tree !ARVORE! -p FETCH_HEAD -m "!MSG!"') do set COMMIT=%%c
) else (
  for /f %%c in ('git commit-tree !ARVORE! -m "!MSG!"') do set COMMIT=%%c
)
git push "!URL!" !COMMIT!:refs/heads/main
if errorlevel 1 (
  echo.
  echo O GitHub recusou o envio. Confira o endereco e se voce entrou com a conta dona do repositorio.
  goto :fim
)
echo.
echo Enviado. O site desse repositorio atualiza sozinho em 1 a 2 minutos ^(aba Actions^).

:fim
if exist "%GIT_INDEX_FILE%" del "%GIT_INDEX_FILE%" >nul 2>nul
echo.
pause
