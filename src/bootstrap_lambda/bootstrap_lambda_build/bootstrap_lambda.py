import os 
import pymysql

def lambda_handler(event, context):
    conn = pymysql.connect(
        host=os.environ['DB_HOST'],
        user=os.environ['DB_USER'],
        password=os.environ['DB_PASSWORD']
    )

    try:
        with conn.cursor() as cursor:
            cursor.execute("CREATE DATABASE IF NOT EXISTS metadata_db;")
            cursor.execute("CREATE DATABASE IF NOT EXISTS visualization_db;")

            cursor.execute("USE visualization_db;")
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS iot_data (
                    id INT AUTO_INCREMENT PRIMARY KEY,
                    thingname VARCHAR(50),
                    time BIGINT,
                    humidity INT,
                    temperature INT
                );
            """)
        conn.commit()
    finally:
        conn.close()

    return {
        "statusCode": 200,
        "body": "Bootstrap complete"
    }