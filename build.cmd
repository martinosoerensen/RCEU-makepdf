docker volume remove makepdf_persist >nul
docker build -t makepdf .
docker volume create --name makepdf_persist
