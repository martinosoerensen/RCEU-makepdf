docker volume remove makepdf_persist
rem docker build -t makepdf .
docker build -t martinosoerensen/rceu-makepdf https://github.com/martinosoerensen/RCEU-makepdf.git
docker volume create --name makepdf_persist
