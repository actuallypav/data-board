import os
import json
import pymysql


def lambda_handler(event, context):
    db_host = os.environ["DB_HOST"]
    db_user = os.environ["DB_USER"]
    db_password = os.environ["DB_PASSWORD"]
    db_name = os.environ["DB_NAME"]

    payload = event if isinstance(event, dict) else json.loads(event)

    conn = pymysql.connect(
        host=db_host, user=db_user, password=db_password, database=db_name
    )

    try:
        with conn.cursor() as cursor:
            sql = """
                INSERT INTO central_heating (thingname, time, humidity, temperature)
                VALUES (%s, %s, %s, %s)
            """
            cursor.execute(
                sql,
                (
                    payload.get("thingname"),
                    payload.get("time"),
                    payload.get("humidity"),
                    payload.get("temperature"),
                ),
            )
        conn.commit()
        print("Insert successful")
    finally:
        conn.close()
    return {"statusCode": 200, "body": json.dumps("Data inserted")}
