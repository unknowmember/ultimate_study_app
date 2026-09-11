@echo off
title Auto Push Appcast Update
color 0A

echo === DANG CHUYEN THU MUC DUA AN ===
cd /d D:\ultimate_study_app

echo.
echo === DANG THEM  VAO GIT ===
git add .

echo.
echo === DANG COMMIT THAY DOI ===
git commit -m "update app"

echo.
echo === DANG PUSH LEN GITHUB ===
git push

echo.
echo =======================================
echo PUSH THANH CONG! Nhan pham bat ky de thoát.
echo =======================================
pause