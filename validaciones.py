import mysql.connector
import dbConfig
from datetime import datetime

def validacionFechasHospedaje(fechaInicio,fechaFin):
    # Validación de las fechas de hospedaje
        if fechaFin < fechaInicio:
                return False
        return True

def disponibilidadHabitacion(idHabitacion,fechaInicio,fechaFin):
    try:
        # Conexión a la base de datos MySQL
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor()

        # Consulta para verificar la disponibilidad de la habitación
        query = """
        SELECT COUNT(*) 
        FROM reserva 
        WHERE id_habitacion = %s 
            AND ( %s  BETWEEN fecha_inicio_hospedaje AND fecha_fin_hospedaje 
            OR %s BETWEEN fecha_inicio_hospedaje AND fecha_fin_hospedaje)
        """

        # Parámetros de la consulta
        params = (idHabitacion, fechaInicio, fechaFin)

        # Ejecutar la consulta
        cursor.execute(query, params)
        result = cursor.fetchone()

        # Verificar si existen reservas solapadas
        if result[0] > 0:
            return False
        else:
            return True

    finally:
        # Cierre del cursor y la conexión a la base de datos
        if connection.is_connected():
            cursor.close()
            connection.close()

def validarUsuario (usuario,clave):
    try:
        # Conexión a la base de datos MySQL
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor()

        # Consulta para validar las credenciales del usuario y obtener el rol
        ##query = """
        ##SELECT c.id ,u.rol
        ##FROM cliente c INNER JOIN usuario u on c.id_usuario = u.id
        ##WHERE u.usuario = %s AND u.clave = %s
        ##"""

        # Parámetros de la consulta
        ##params = (usuario, clave)

        # Ejecutar la consulta
        results = cursor.callproc('sp_validar_usuario',[usuario,clave])
        ##result = cursor.fetchone()
        results= []
        for result in cursor.stored_results():
             results.extend(result.fetchall())

        # Verificar si las credenciales son válidas
        if results:
            #rol = results
            return results[0]
        else:
            return None

    finally:
        # Cierre del cursor y la conexión a la base de datos
        if connection.is_connected():
            cursor.close()
            connection.close()
        
def validarExistenciaHabitacion(numero_habitacion):
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor()

        query = """
        SELECT 1 
        FROM habitacion 
        WHERE numero_habitacion = %s 
        """

        params = (numero_habitacion)

        cursor.execute(query, params)
        result = cursor.fetchone()

        if result[0] > 0:
            return False
        else:
            return True

    finally:
        if connection.is_connected():
            cursor.close()
            connection.close()

def cliente_existe(idCliente, cursor):
    cursor.execute("SELECT id FROM cliente WHERE id = %s", (idCliente,))
    return cursor.fetchone() is not None

def habitacion_existe(idHabitacion, cursor):
    cursor.execute("SELECT id FROM habitacion WHERE id = %s", (idHabitacion,))
    return cursor.fetchone() is not None

def validar_fecha_formato(fecha):
    try:
        # Intentar analizar la fecha en el formato deseado
        datetime.strptime(fecha, "%Y-%m-%d")
        return True
    except ValueError:
        return False