@echo off
cd /d "%~dp0backend"
echo Running tests, saving output to D:\test_output.txt...
python -m pytest tests/ -v --tb=long > D:\test_output.txt 2>&1
echo Done! Check D:\test_output.txt
pause
