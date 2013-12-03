#!/bin/bash
REDIS_ID=$(docker ps | grep "stackbrew/hipache:latest" | head -1 | awk '{print $1}')
REDIS_PORT=$(docker port $REDIS_ID 6379 | sed 's/0.0.0.0://')

while true; 
do 
  data=`nc -l 0.0.0.0 1234`;
  IFS=" " read -ra PARAMS <<< "$data"
  CMD=${PARAMS[0]}
  APP=${PARAMS[1]}
  COUNT=${PARAMS[2]}

  case "${CMD}" in
    run)
      echo "URUCHOM ${COUNT} INSTANCJI APLIKACJI ${APP}";
      CUR_COUNT=`sudo docker ps | grep $APP | wc -l`
      echo "APLIKACJA URUCHOMINA W ${CUR_COUNT} INSTANCJACH"
      DIFF=$(( $CUR_COUNT - $COUNT ))

      if [ $DIFF -lt 0 ]; then
        DIFF2=$(( $COUNT - $CUR_COUNT ))
        echo "URUCHAMIAM $DIFF2 INSTANCJI"
        for i in $(seq 1 $DIFF2)
        do
          ID=$(sudo docker run -e PORT=8000 -p 8000 -d $APP /bin/bash -c "/start web")
          PORT=$(docker port $ID 8000 | sed 's/0.0.0.0://')
          redis-cli -p $REDIS_PORT rpush "frontend:zadanie.example.com" "http://192.168.33.11:$PORT" > /dev/null
        done
      else
        echo "ZATRZYMUJE $DIFF INSTANCJI"
        for i in $(seq 1 $DIFF)
        do
          ID=`sudo docker ps | grep "project:latest" | head -1 | awk '{print $1}'`
          PORT=$(docker port $ID 8000 | sed 's/0.0.0.0://')
          sudo docker kill $ID > /dev/null
          redis-cli -p $REDIS_PORT LREM "frontend:zadanie.example.com" 1 "http://192.168.33.11:$PORT" > /dev/null
        done
      fi
      echo "GOTOWE"
    ;;
  esac 
done
