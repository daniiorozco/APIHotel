from flask import Flask, jsonify, request, abort
from flask_cors import CORS
from functools import wraps
import mysql.connector
import jwt
import dbConfig
import validaciones
from config import SECRET_KEY

app = Flask(__name__)
CORS(app)
app.config['SECRET_KEY'] = SECRET_KEY


# ------------------------end point LOGIN----------
@app.route('/login', methods=['POST'])
def login():
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        data = request.get_json()

        usuario = data['usuario']
        clave = data['clave']

        rol = validaciones.validarUsuario(usuario, clave)

        secret = app.config['SECRET_KEY']

        if rol[1]:
            payload = {"usuario": usuario,"id" : rol[0], "rol": rol[1]}

            token = jwt.encode(payload, secret, algorithm='HS256')

            # Devolver el token en la respuesta
            return jsonify({'token': token, 'rol' : rol})
        else:
            return jsonify({'status': 401 , "message" :'Credenciales inválidas.'}), 401

    except Exception as e:
        return jsonify({'error': str(e)})

#funcion para verificar las rutas con el token y rol
def rutaProtegida(rol_esperado):
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            try:
                token = request.headers.get('Authorization')

                if token:
                    # Verificar y decodificar el token JWT
                    payload = jwt.decode(token, app.config['SECRET_KEY'], algorithms=['HS256'])

                    rol = payload.get('rol')

                    if rol == rol_esperado:
                        return f(*args, **kwargs)
                    else:
                        msg = 'No tiene permiso de acceso a la informacion'
                        return jsonify({"status" : 403 ,'message': msg}), 403
                else:
                    msg = 'Debe estar autenticado previamente'
                    return jsonify({"status" : 401 ,'message': msg}) , 401
            except Exception as e:
                pass
                msg = 'Error interno del servidor'
                return jsonify({"status" : 500 ,'message': msg}) , 500
        return wrapper
    return decorator



# -----------------------end point crear user Cliente----------


@app.route('/clientes', methods=['POST'])
def createCliente():
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        data = request.get_json()

        usuario = data['usuario']
        clave = data['clave']
        nombre = data['nombre']
        apellido = data['apellido']

        cursor.callproc('spi_cliente', [usuario, clave, nombre, apellido])

        connection.commit()
        msg = 'Se inserto correctamente el cliente'
        return jsonify({'message': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()

# ----------------------end points habitaciones----------


@app.route('/habitaciones', methods=['POST'])
@rutaProtegida('empleado')
def createHabitacion():
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        data = request.get_json()

        numero_habitacion = data['numero_habitacion']
        precio = data['precio']
        estado = data['estado']

        if not (isinstance(numero_habitacion, int) and numero_habitacion > 0):
            return jsonify({'error': 'El número de habitación debe ser un número entero mayor a 0.'}), 400

        if not (isinstance(precio, (int, float)) and precio > 0):
            return jsonify({'error': 'El precio debe ser un número mayor a 0.'}), 400

        if not (isinstance(estado, int) and estado in [0, 1]):
            return jsonify({'error': 'El estado debe ser 0 (No disponible) o 1 (Disponible).'}), 400
        
        # Verificar si el número de habitación ya existe en la base de datos
        cursor.execute("SELECT id FROM habitacion WHERE numero_habitacion = %s", (numero_habitacion,))
        if cursor.fetchone():
            return jsonify({'error': 'El número de habitación ya existe.'}), 400

        cursor.callproc('spi_habitacion', [numero_habitacion, precio, estado])

        connection.commit()
        msg = 'Se inserto correctamente la habitación'
        return jsonify({'message': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()


@app.route('/habitaciones/<numHabitacion>/precio', methods=['PUT'])
@rutaProtegida('empleado')
def updateHabitacionPrecio(numHabitacion):
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        data = request.get_json()

        precio = data['precio']

        if not (isinstance(precio, (int, float)) and precio > 0):
            return jsonify({'error': 'El precio debe ser un número mayor a 0.'}), 400

        cursor.callproc('spu_precio_habitacion', [numHabitacion, precio])

        connection.commit()
        msg = 'Se modifico correctamente la habitación'
        return jsonify({'message': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()


@app.route('/habitaciones/<numHabitacion>/estado', methods=['PUT'])
@rutaProtegida('empleado')
def updateHabitacionEstado(numHabitacion):
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        data = request.get_json()

        estado = data['estado']

        if not (isinstance(estado, int) and estado in [0, 1]):
            return jsonify({'error': 'El estado de la habitación debe ser 0 (No disponible) o 1 (Disponible).'}), 400

        cursor.callproc('spu_estado_habitacion', [numHabitacion, estado])

        connection.commit()
        msg = 'Se modifico correctamente la habitación'
        return jsonify({'message': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()

# ---------------------------end points RESERVAS---------------------

@app.route('/reservas', methods=['GET'])
@rutaProtegida('empleado')
def getReservas():
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        results = cursor.callproc('sps_reservas')

        for result in cursor.stored_results():
            results = result.fetchall()

        if results:
            return jsonify({'data': results})
        else:
            msg = "No hay information para mostar"
            return jsonify({'data': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()


@app.route('/reservas/fecha/<fecha>', methods=['GET'])
@rutaProtegida('empleado')
def getReservaPorFecha(fecha):
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        results = cursor.callproc('sps_reserva_x_fecha', [fecha])

        for result in cursor.stored_results():
            results = result.fetchall()

        if results:
            return jsonify({'data': results})
        else:
            msg = "No hay information para mostar"
            return jsonify({'data': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()


@app.route('/reservas', methods=['POST'])
@rutaProtegida('cliente')
def createReserva():

    try:
        # Connect to MySQL database
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        data = request.get_json()

        idCliente = data['p_id_cliente']
        idHabitacion = data['p_id_habitacion']
        fechaInicio = data['p_fecha_inicio_hospedaje']
        fechaFin = data['p_fecha_fin_hospedaje']

        if not validaciones.cliente_existe(idCliente, cursor):
            return jsonify({'error': 'El idCliente especificado no existe.'}), 400

        if not validaciones.habitacion_existe(idHabitacion, cursor):
            return jsonify({'error': 'El idHabitacion especificado no existe.'}), 400
        
        if not validaciones.validar_fecha_formato(fechaInicio) or not validaciones.validar_fecha_formato(fechaFin):
            return jsonify({'error': 'El formato de fecha debe ser "año-mes-día" (por ejemplo, "2023-07-15").'}), 400

        if not validaciones.validacionFechasHospedaje(fechaInicio, fechaFin):
            return jsonify({'error': 'La fecha de fin de hospedaje no puede ser menor que la fecha de inicio de hospedaje.'}),400

        if not validaciones.disponibilidadHabitacion(idHabitacion, fechaInicio, fechaFin):
            return jsonify({'error': 'La habitación no está disponible para el período especificado.'}), 400
        
        cursor.callproc('spi_reserva', [idCliente, idHabitacion, fechaInicio, fechaFin])

        connection.commit()

        msg = 'Se inserto correctamente la reserva'
        return jsonify({'message': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        # Close the cursor and the database connection
        if (connection.is_connected()):
            cursor.close()
            connection.close()

# -----------------------------Busqueda--------------------------

@app.route('/habitaciones', methods=['GET'])
@rutaProtegida('cliente')
def habitacionesDisponibles():
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        fechaInicio = request.args.get('fecha_inicio')
        fechaFin = request.args.get('fecha_fin')

        results = cursor.callproc('sps_habitaciones_x_fechas', [fechaInicio, fechaFin])

        for result in cursor.stored_results():
            results = result.fetchall()

        if results:
            return jsonify( results)
        else:
            msg = "No hay information para mostar"
            return jsonify({'data': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()


@app.route('/habitaciones/fecha/<fecha>', methods=['GET'])
@rutaProtegida('cliente')
def listHabitaciones(fecha):
    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        results = cursor.callproc('sps_habitaciones', [fecha])

        for result in cursor.stored_results():
            results = result.fetchall()

        if results:
            return jsonify({'data': results})
        else:
            msg = "No hay information para mostar"
            return jsonify({'data': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()


@app.route('/habitaciones/precio/<precio>', methods=['GET'])
@rutaProtegida('cliente')
def getHabitacionesPrecio(precio):

    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        cursor.callproc('sps_habitaciones_x_precio', [precio])

        for result in cursor.stored_results():
            results = result.fetchall()

        if results:
            return jsonify({'data': results})
        else:
            msg = "No hay information para mostar"
            return jsonify({'data': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()


@app.route('/habitaciones/<id>')
@rutaProtegida('empleado')
def getHabitacion(id):

    try:
        connection = mysql.connector.connect(**dbConfig.db_config)
        cursor = connection.cursor(dictionary=True)

        cursor.callproc('sps_habitaciones_x_numero', [id])

        for result in cursor.stored_results():
            results = result.fetchall()

        if results:
            return jsonify({'data': results})
        else:
            msg = "No hay information para mostar"
            return jsonify({'data': msg})

    except Exception as e:
        return jsonify({'error': str(e)})
    finally:
        if (connection.is_connected()):
            cursor.close()
            connection.close()


if __name__ == '__main__':
    app.run(debug=True, port=5000)
