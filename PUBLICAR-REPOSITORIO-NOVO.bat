@echo off
title Minha Voz - publicar em um repositorio NOVO
cd /d "%~dp0"
echo ==========================================================
echo   Publicar o Minha Voz em um repositorio NOVO do GitHub
echo   (versao separada, com historico proprio, comecando do zero)
echo ==========================================================
echo.
echo O repositorio antigo NAO e alterado. Depois, para atualizar qualquer
echo um deles (o antigo ou o novo), use o ENVIAR-PARA-GITHUB.bat.
echo.

where git >nul 2>nul || (echo Falta instalar o Git: https://git-scm.com & pause & exit /b 1)

git config user.name >nul 2>nul && goto :temEmail
set /p NOME=Seu usuario do GitHub: 
git config --global user.name "%NOME%"
:temEmail
git config user.email >nul 2>nul && goto :escolher
set /p EMAIL=Seu e-mail do GitHub: 
git config --global user.email "%EMAIL%"

:escolher
set NOMEREPO=minha-voz-v2
set /p NOMEREPO=Nome do repositorio novo (Enter = minha-voz-v2): 
set URL=
set DONO=

rem Com o GitHub CLI (gh) instalado e logado, o repositorio e criado sozinho.
where gh >nul 2>nul || goto :manual
gh auth status >nul 2>nul || goto :manual
set CRIAR=S
set /p CRIAR=Criar o repositorio %NOMEREPO% automaticamente? (S/N, Enter = S): 
if /i not "%CRIAR%"=="S" goto :manual
for /f "delims=" %%u in ('gh api user -q .login') do set DONO=%%u
gh repo create "%NOMEREPO%" --public || (echo Nao foi possivel criar. Talvez o nome ja exista. & pause & exit /b 1)
set URL=https://github.com/%DONO%/%NOMEREPO%.git
goto :enviar

:manual
echo.
echo Vou abrir a pagina de criar repositorio no navegador. Nela:
echo   1. Entre com a conta que vai ser dona do projeto.
echo   2. Repository name: %NOMEREPO%
echo   3. Marque Public.
echo   4. NAO marque README, .gitignore nem licenca. Clique em Create repository.
echo   5. Copie o endereco que aparece (termina em .git).
echo.
pause
start "" "https://github.com/new?name=%NOMEREPO%&visibility=public"
echo.
set /p URL=Cole aqui o endereco do repositorio novo e aperte Enter: 
if "%URL%"=="" (echo Nenhum endereco informado. & pause & exit /b 1)

:enviar
echo.
echo Montando a versao nova (um unico commit) e enviando para:
echo   %URL%
set GD=%TEMP%\minhavoz-novo-%RANDOM%%RANDOM%
git --git-dir="%GD%" --work-tree="%CD%" init -q -b main || goto :erro
git --git-dir="%GD%" --work-tree="%CD%" add -A || goto :erro
git --git-dir="%GD%" --work-tree="%CD%" commit -q -m "Minha Voz - versao publicada em %NOMEREPO%" || goto :erro
git --git-dir="%GD%" --work-tree="%CD%" push "%URL%" main
if errorlevel 1 goto :recusado
rmdir /s /q "%GD%" >nul 2>nul
rem Coloca o repositorio novo na lista do ENVIAR-PARA-GITHUB.bat
if not exist repositorios-github.txt echo https://github.com/AnaDevv24/minha-voz.git> repositorios-github.txt
echo %URL%>> repositorios-github.txt

if "%DONO%"=="" goto :semgh
rem Liga o GitHub Pages (Source = GitHub Actions) sozinho
gh api -X POST "repos/%DONO%/%NOMEREPO%/pages" -f build_type=workflow >nul 2>nul
gh workflow run pages.yml -R "%DONO%/%NOMEREPO%" >nul 2>nul
echo.
echo Pronto. Repositorio: https://github.com/%DONO%/%NOMEREPO%
echo O site fica em https://%DONO%.github.io/%NOMEREPO%/ quando a aba Actions ficar verde.
goto :fim

:semgh
echo.
echo Pronto. Falta so ligar o site:
echo   No repositorio novo: Settings ^> Pages ^> Source = GitHub Actions.
echo   Depois, na aba Actions, clique em "Publicar no GitHub Pages" ^> Run workflow.
echo   O site fica em https://SEU-USUARIO.github.io/%NOMEREPO%/
goto :fim

:recusado
rmdir /s /q "%GD%" >nul 2>nul
echo.
echo O GitHub recusou o envio. Confira se:
echo   - o repositorio foi criado VAZIO (sem README);
echo   - voce entrou com a conta dona do repositorio quando o navegador pediu.
goto :fim

:erro
rmdir /s /q "%GD%" >nul 2>nul
echo Algo deu errado ao montar a versao. Veja a mensagem acima.

:fim
echo.
pause
