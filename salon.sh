#!/bin/bash

# Configurar la conexión a la base de datos
PSQL="psql --username=freecodecamp --dbname=salon -t --no-align -c"

# Muestra la lista de sercicios
display_services() {
  echo -e "\nHere are the services we offer:"
  SERVICES=$($PSQL "SELECT service_id, name FROM services")
  echo "$SERVICES" | while IFS='|' read SERVICE_ID SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done
}

# Agregar un cliente si no existe
add_customer_if_not_exists() {
  CUSTOMER_PHONE=$1
  CUSTOMER_NAME=$2

  EXISTING_CUSTOMER=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z $EXISTING_CUSTOMER ]]
  then
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')")
    EXISTING_CUSTOMER=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  fi

  echo $EXISTING_CUSTOMER
}

# Lógica del código princial
main() {
  while true
  do
    display_services
    echo -e "\nPlease select a service by entering the service_id:"
    read SERVICE_ID_SELECTED

    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")

    if [[ -z $SERVICE_NAME ]]
    then
      echo "Invalid service ID. Please try again."
    else
      break
    fi
  done

  echo -e "\nEnter your phone number:"
  read CUSTOMER_PHONE

  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")

  if [[ -z $CUSTOMER_NAME ]]
  then
    echo -e "\nIt seems you're a new customer. Please enter your name:"
    read CUSTOMER_NAME
    CUSTOMER_ID=$(add_customer_if_not_exists "$CUSTOMER_PHONE" "$CUSTOMER_NAME")
  else
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  fi

  echo -e "\nAt what time would you like to schedule your appointment?"
  read SERVICE_TIME

  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

  if [[ $INSERT_APPOINTMENT_RESULT == "INSERT 0 1" ]]
  then
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  else
    echo -e "\nSomething went wrong. Please try again."
  fi
}

main