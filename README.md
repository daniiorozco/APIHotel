## APIHotel

### Descrpción
Un servicio de API para gestionar un Hotel, cuanta con login donde se pueden loguear dos tipos de usuarios Empleado/Cliente;
Dependiendo de su rol va a poder acceder a cierta información del sistema.

### Tecnologías
![image](https://github.com/daniiorozco/APIHotel/assets/101194558/0154d845-5c1a-47c6-852f-b2bccef04a13)

![image](https://github.com/daniiorozco/APIHotel/assets/101194558/35e2ba11-3fd3-4c41-8949-53a3a4744872)

![image](https://github.com/daniiorozco/APIHotel/assets/101194558/f9b93d28-9ff5-4f6a-98ab-1620a78050ad)

![image](https://github.com/daniiorozco/APIHotel/assets/101194558/aac66a30-5373-4be5-a3d7-38bb048898ab)

### Configuración para uso
En primer lugar es necesario que tengas instalado python en tu notebook (Para mi proyecto use la version 3.0.0).
Lo siguiente es crear un entorno virtual, para eso vas abrir una consola, decide en que carpeta quieres crearlo y ejecuta el módulo venv como script con la ruta a la carpeta:
python -m venv nombreCarpeta
<br/>
<br/>
Una vez creado el entorno virtual, podrás activarlo:
<br/>
nombreCarpeta\Scripts\activate.bat
<br/>
<br/>
Una vez activado el entorno virtual y haber descargado el proyecto y ubicado en tu carpeta local, vas a descargar las librerias que utiliza el proyecto para eso en la consola
pones el siguiente comando:
<br/>
'pip install requirements.txt'
<br/>
<br/>
Para la Base de Datos se usa MySQL, la unica configuración seria correr el script .sql en el programa que uses, ya sea phpmyadmin u otro.
<br/>
Tmbien es importante que crees dos archivos uno para la configuracion de la BDD y otro para establecer la palabra secreta del JWT.
<br/>
En mi mi caso lo llame el archivo dbConfig
### Configuración de la base de datos MySQL
db_config = {
    'user': 'tuUsuario',
    'password': 'tuPassword',
    'host': 'tuHost',
    'database': 'nombreBDD'
}

<br/>
y el archivo donde va la palabra secreta pones lo siguiente : SECRET_KEY= 'tuPalabraSecreta'




