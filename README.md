# Proyecto Corto III: División Entera Sin Signo en FPGA

Integrantes

* Franco Jesús Plano
* Dante Ignacio Muñoz Vidal

Curso: EL-3307 Diseño Lógico I
Fecha de entrega: 9 de junio de 2026
Plataforma: Tang Nano 9K



## 1. Introducción

En este proyecto se desarrolló un sistema digital sincrónico en HDL orientado a la implementación de una unidad de división entera sin signo sobre una FPGA Tang Nano 9K. El sistema permite ingresar un dividendo y un divisor mediante un teclado matricial, almacenar ambos operandos, ejecutar la operación de división y desplegar en cuatro displays de 7 segmentos tanto el cociente como el residuo.

El desarrollo del proyecto permitió integrar conceptos fundamentales de diseño lógico digital, tales como lectura de entradas externas, eliminación de rebotes, diseño modular, máquinas de estados finitos, protocolos de comunicación entre módulos, operaciones aritméticas secuenciales y despliegue multiplexado en displays de 7 segmentos.

A diferencia de una implementación directa mediante operadores aritméticos de alto nivel, la unidad divisora se diseñó mediante una arquitectura secuencial basada en desplazamiento y resta. Esto permitió controlar el proceso de división por ciclos de reloj y separar claramente la lógica de control de la lógica aritmética.



## 2. Definición general del problema, objetivos y especificaciones

El problema planteado consiste en diseñar un circuito digital sincrónico capaz de realizar una división entera sin signo. El sistema debe permitir ingresar un dividendo y un divisor desde un teclado, procesar la operación dentro de la FPGA y mostrar el resultado mediante displays de 7 segmentos.

Las principales restricciones consideradas fueron:

* El dividendo debe ser representable en un máximo de 6 bits, por lo que su rango es de 0 a 63.
* El divisor debe ser representable en un máximo de 4 bits, por lo que su rango es de 0 a 15.
* El sistema debe entregar dos resultados: cociente y residuo.
* La entrada de datos se realiza mediante un teclado matricial.
* La salida se muestra en cuatro displays de 7 segmentos.
* El diseño debe operar con el reloj principal de 27 MHz de la Tang Nano 9K.
* Las entradas externas deben ser acondicionadas mediante sincronización y eliminación de rebotes.
* La operación debe implementarse de forma modular.

El objetivo general del proyecto fue implementar una unidad de división entera sin signo en HDL, integrándola con un sistema de captura de datos y despliegue en 7 segmentos.

Como objetivos específicos se plantearon:

* Reutilizar módulos desarrollados previamente para lectura de teclado y control de display.
* Diseñar una unidad divisora secuencial sin signo.
* Implementar un protocolo de control entre el módulo principal y el divisor mediante señales valid y done.
* Permitir la visualización tanto del cociente como del residuo.
* Verificar el funcionamiento mediante simulaciones funcionales y pruebas físicas en FPGA.



## 3. Descripción general del funcionamiento del circuito completo

El sistema completo se divide en varios subsistemas interconectados. El flujo general inicia con el reloj principal de 27 MHz, el cual es reducido mediante un divisor de reloj para generar una base de tiempo adecuada para la lectura del teclado y el refrescamiento de los displays.

El teclado matricial permite ingresar números y comandos especiales. Los dígitos numéricos se acumulan en el controlador de display para formar el número que el usuario desea almacenar. La tecla A se utiliza para guardar el número mostrado como dividendo, mientras que la tecla B guarda el número mostrado como divisor. Una vez almacenados ambos operandos, la tecla D inicia la división.

La división es ejecutada por el módulo m8_divisor, el cual recibe el dividendo y divisor desde el módulo de control principal. Este divisor no usa los operadores / ni %, sino que aplica un algoritmo secuencial de desplazamiento y resta. Al finalizar, entrega el cociente, el residuo y una señal done.

El módulo m7_calculadora actúa como controlador principal. Este módulo interpreta las teclas, guarda operandos, inicia la división, espera el resultado y decide qué dato cargar hacia el display. Después de ejecutar la división con D, se muestra automáticamente el cociente. Además, se permite consultar el residuo mediante la tecla * y volver a mostrar el cociente mediante la tecla #.

Finalmente, el módulo de display convierte el valor interno a una representación compatible con los cuatro displays de 7 segmentos. El sistema fue probado mediante simulaciones y posteriormente validado en la FPGA.



## 4. Interfaz de usuario

La asignación final de teclas fue la siguiente:

Tecla	Función
0 - 9	Ingreso de dígitos numéricos
A	Guardar el número actual como dividendo
B	Guardar el número actual como divisor
C	Limpiar sistema
D	Ejecutar división
*	Mostrar residuo
#	Mostrar cociente

El flujo normal de operación es:

Ingresar dividendo
Presionar A
Ingresar divisor
Presionar B
Presionar D para dividir
Presionar * para ver residuo
Presionar # para volver a ver cociente

Por ejemplo, para calcular 58 / 5:

5 8 A
5 B
D   -> muestra cociente
*   -> muestra residuo
#   -> muestra cociente



## 5. Descripción general de cada subsistema

### 5.1 Subsistema de división de reloj: m1_clk_divider

El módulo m1_clk_divider genera una señal de reloj más lenta a partir del reloj principal de 27 MHz. Esta señal derivada se utiliza para procesos que no requieren operar a la máxima frecuencia de la FPGA, como el barrido del teclado, la eliminación de rebotes y el refrescamiento del display.

La reducción de frecuencia permite que el sistema interactúe correctamente con elementos físicos externos, especialmente el teclado matricial, cuyas señales varían a velocidades mucho menores que el reloj principal.



### 5.2 Subsistema de eliminación de rebote: m2_DeBounce

El módulo m2_DeBounce se encarga de filtrar las señales provenientes del teclado. Debido a que las teclas son elementos mecánicos, al presionarlas pueden generarse transiciones rápidas no deseadas conocidas como rebotes.

Este módulo permite estabilizar la lectura de cada tecla antes de que el sistema la procese. Esto evita que una sola pulsación sea interpretada como múltiples pulsaciones.



### 5.3 Subsistema de lectura del teclado: m3_keypad_reader

El módulo m3_keypad_reader implementa el barrido del teclado matricial. Su función es activar columnas de forma secuencial y leer las filas para determinar qué tecla fue presionada.

Este módulo entrega dos señales principales:

key_code  -> código de la tecla presionada
key_valid -> indica que se detectó una tecla válida

Los códigos usados para las teclas especiales fueron:

A = 4'hA
B = 4'hB
C = 4'hC
D = 4'hD
* = 4'hE
# = 4'hF



### 5.4 Subsistema de control de display: m4_display_controller

El módulo m4_display_controller administra el contenido lógico que será mostrado en los displays. Este bloque no enciende directamente los segmentos, sino que mantiene el dato de pantalla en una señal de 16 bits llamada display_data.

Cada nibble de display_data representa un dígito o símbolo. Por ejemplo:

CCCC -> pantalla limpia
CCC5 -> muestra 5
CC15 -> muestra 15
CC58 -> muestra 58
CEEE -> error

Este módulo recibe dígitos desde el teclado y los va acumulando. También puede recibir órdenes desde m7_calculadora para limpiar la pantalla o cargar un resultado.



### 5.5 Subsistema de captura numérica: m5_number_capture

El módulo m5_number_capture se utilizó como apoyo para la captura de valores numéricos desde el teclado durante la implementación en FPGA. Su función es estructurar los dígitos ingresados por el usuario y validar que los valores se mantengan dentro del rango permitido.

Este bloque resulta útil para separar la lógica de ingreso de datos de la lógica de control principal, manteniendo el diseño más modular y fácil de verificar.



### 5.6 Subsistema de despliegue en 7 segmentos: m6_seven_segment_driver

El módulo m6_seven_segment_driver convierte el valor contenido en display_data a las señales físicas necesarias para controlar los displays de 7 segmentos.

Este módulo realiza dos tareas principales:

* Decodificar cada nibble a su patrón correspondiente de segmentos.
* Multiplexar los cuatro dígitos para que puedan visualizarse usando un número reducido de señales.

Gracias al multiplexado, los cuatro displays se refrescan rápidamente, dando la impresión visual de que todos permanecen encendidos al mismo tiempo.



### 5.7 Subsistema de control principal: m7_calculadora

El módulo m7_calculadora es el controlador principal del sistema. Su función es coordinar el flujo completo de la operación.

Este módulo se encarga de:

* Interpretar las teclas especiales.
* Guardar el dividendo cuando se presiona A.
* Guardar el divisor cuando se presiona B.
* Limpiar el sistema cuando se presiona C.
* Iniciar la división cuando se presiona D.
* Mostrar el residuo cuando se presiona *.
* Mostrar el cociente cuando se presiona #.
* Controlar las señales hacia el módulo divisor.
* Controlar la carga de resultados hacia el display.

El diseño de este módulo se basó en una máquina de estados finitos. Esta FSM permite ordenar el proceso en pasos claros: espera de comandos, preparación de operandos, envío de la señal valid, espera de la señal done y captura del resultado.



### 5.8 Subsistema de división entera: m8_divisor

El módulo m8_divisor implementa la operación de división entera sin signo. Recibe un dividendo de 6 bits y un divisor de 4 bits, y entrega un cociente de 6 bits y un residuo de 4 bits.

El algoritmo utilizado es de desplazamiento y resta. En cada ciclo, el divisor compara el residuo parcial contra el divisor. Si el divisor cabe dentro del residuo parcial, se realiza una resta y se coloca un 1 en el bit correspondiente del cociente. Si no cabe, se coloca un 0.

Como el dividendo tiene 6 bits, el divisor procesa la operación desde el bit más significativo hasta el menos significativo, requiriendo aproximadamente seis ciclos de procesamiento.

El módulo incluye una protección contra división entre cero. En caso de recibir divisor cero, entrega cociente cero, residuo cero y activa done.



### 5.9 Módulo superior: top_module

El módulo top_module integra todos los subsistemas anteriores. Define las conexiones entre el reloj, el teclado, la lógica de control, la unidad divisora y el sistema de despliegue en 7 segmentos.

Este bloque representa la implementación final cargada en la FPGA.


## 6. Diagrama general del sistema

El siguiente diagrama muestra la interconexión general de los módulos principales del sistema.

          ┌──────────────────────────────────────────────────────────────┐
          │                         top_module                           │
          │                                                              │
          │  ┌───────────────┐                                           │
clk 27MHz ──▶│ m1_clk_divider │                                           │
          │  └───────┬───────┘                                           │
          │          │ clk_1khz                                          │
          │          ▼                                                   │
          │  ┌───────────────┐                                           │
rows ───────▶│ m3_keypad_    │── key_code ─────┐                         │
          │  │ reader        │── key_valid ────┤                         │
cols ◀───────│               │                 │                         │
          │  └───────────────┘                 │                         │
          │                                    ▼                         │
          │                            ┌───────────────┐                 │
          │                            │ m4_display_   │◀────────────┐   │
          │                            │ controller    │             │   │
          │                            └───────┬───────┘             │   │
          │                                    │ display_data         │   │
          │                                    ▼                     │   │
          │                            ┌───────────────┐             │   │
          │                            │ m6_seven_     │             │   │
          │                            │ segment_driver│             │   │
          │                            └───────┬───────┘             │   │
          │                                    │                     │   │
          │                                  seg, an                 │   │
          │                                                          │   │
          │                            ┌───────────────┐             │   │
          │                            │ m7_calculadora│─────────────┘   │
          │                            │ FSM control   │                 │
          │                            └───────┬───────┘                 │
          │                                    │ valid, operandos         │
          │                                    ▼                         │
          │                            ┌───────────────┐                 │
          │                            │ m8_divisor    │                 │
          │                            │ shift-subtract│                 │
          │                            └───────────────┘                 │
          │                                                              │
          └──────────────────────────────────────────────────────────────┘



## 7. Diagramas de estado de las FSM diseñadas

### 7.1 FSM principal de m7_calculadora

La FSM principal controla el flujo de operación del sistema.

                 ┌─────────────────┐
                 │     ST_IDLE     │
                 └───┬────┬────┬───┘
                     │    │    │
       tecla A ──────┘    │    └──── tecla D
       guarda dividendo   │
                          │
       tecla B ───────────┘
       guarda divisor
       tecla C -> limpia sistema
       tecla * -> muestra residuo
       tecla # -> muestra cociente
                          │
                          ▼
                 ┌─────────────────┐
                 │  ST_START_DIV   │
                 │ coloca operandos│
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │ ST_SEND_VALID   │
                 │ valid = 1       │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │  ST_WAIT_DONE   │
                 │ espera done     │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │ST_CAPTURE_RESULT│
                 │ guarda resultado│
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │     ST_IDLE     │
                 └─────────────────┘

### 7.2 FSM de m8_divisor

El divisor utiliza una FSM más simple, con dos estados principales.

          ┌───────────┐
          │  ST_IDLE  │
          │ espera    │
          │ valid     │
          └─────┬─────┘
                │ valid = 1
                ▼
          ┌───────────┐
          │  ST_RUN   │
          │ desplaza  │
          │ y resta   │
          └─────┬─────┘
                │ termina bit 0
                ▼
          ┌───────────┐
          │  ST_IDLE  │
          │ done = 1  │
          └───────────┘



## 8. Algoritmo de división utilizado

La unidad divisora se implementó mediante el algoritmo de desplazamiento y resta.

El procedimiento general es:

1. Se guarda el dividendo y el divisor.
2. Se inicializa el cociente y el residuo en cero.
3. Se procesa el dividendo desde el bit más significativo hasta el menos significativo.
4. En cada ciclo se desplaza el residuo parcial y se baja un bit del dividendo.
5. Si el divisor cabe dentro del residuo parcial, se resta y se coloca un 1 en el bit correspondiente del cociente.
6. Si el divisor no cabe, no se resta y se coloca un 0 en el bit correspondiente del cociente.
7. Al finalizar todos los bits, se publican el cociente y el residuo.

Por ejemplo:

58 / 5 = cociente 11, residuo 3

ya que:

5 × 11 = 55
58 - 55 = 3



## 9. Ejemplo y análisis de simulación funcional

Para verificar el diseño se realizaron simulaciones funcionales de los módulos principales y del sistema completo. Se utilizaron testbenches para comprobar la lectura del teclado, el controlador principal, la unidad divisora y la integración del top_module.

Entre los casos simulados se incluyeron:

Operación	Cociente esperado	Residuo esperado	Resultado en simulación
15 / 3	5	0	Correcto
13 / 4	3	1	Correcto
63 / 15	4	3	Correcto en simulación
50 / 5	10	0	Correcto
48 / 8	6	0	Correcto
58 / 5	11	3	Correcto en simulación
38 / 7	5	3	Correcto en simulación
58 / 11	5	3	Correcto en simulación
10 / 0	Error	Error	Correcto

Las simulaciones permitieron validar el funcionamiento lógico esperado del sistema. Además, ayudaron a identificar problemas de sincronización entre el controlador principal y el divisor, especialmente en el uso de las señales valid y done. Para solucionar esto, se separó la colocación de operandos y la activación de valid en estados distintos de la FSM.



## 10. Resultados obtenidos en FPGA

Durante la validación física en la FPGA Tang Nano 9K, el sistema logró ejecutar correctamente múltiples operaciones de división entera sin signo. Se verificó el ingreso de operandos mediante teclado, el almacenamiento de dividendo y divisor, la ejecución de la división y el despliegue del cociente y residuo.

La mayoría de las pruebas de bajo y medio rango mostraron un comportamiento correcto. Sin embargo, durante la validación física se observaron inconsistencias en algunos casos específicos, principalmente asociados a divisiones con residuos distintos de cero y a ciertos casos límite.

Caso evaluado	Observación general
15 / 3	Funcionamiento correcto
13 / 4	Funcionamiento correcto
50 / 5	Funcionamiento correcto después de ajustes
48 / 8	Funcionamiento correcto después de ajustes
58 / 5	Se observó inconsistencia inicial en el despliegue del residuo
38 / 7	Se observó inconsistencia inicial en el despliegue del residuo
63 / 15	Caso límite con comportamiento no estable durante la prueba física
20 / 4	Resultado distinto al esperado durante una prueba física

Estas observaciones permitieron identificar oportunidades de mejora en la depuración del módulo divisor y en su integración con el sistema de visualización. A pesar de estas limitaciones, la arquitectura general del sistema logró cumplir la funcionalidad principal de captura de operandos, ejecución de división y despliegue de resultados.



## 11. Análisis de consumo de recursos en la FPGA

Una vez finalizada la descripción RTL del sistema, el diseño fue sintetizado e implementado para la FPGA Tang Nano 9K. El objetivo de esta etapa fue estimar la cantidad de recursos físicos utilizados por el circuito, incluyendo LUTs, flip-flops, pines de entrada/salida y recursos de reloj.

| Recurso Lógico / Físico | Utilizado | Total Disponible | Utilización (%) |
| :--- | :---: | :---: | :---: |
| LUTs (*Look-Up Tables*) | 950 | 8,640 | 10.99% |
| Registros (Flip-Flops) | 174 | 8,640 | 2.01% |
| Bloques I/O (Pines físicos) | 21 | 274 | 7.66% |
| Recursos de Reloj (Buffers/Red) | 2 | 16 | 12.5% |

La utilización de recursos obtenida muestra que el diseño ocupa una fracción reducida de la FPGA, debido a que la arquitectura se basa principalmente en lógica combinacional, registros, máquinas de estado, contadores y un divisor secuencial. Los módulos de mayor impacto corresponden al divisor entero, la lógica de control principal, el lector de teclado y el controlador de despliegue en 7 segmentos.



## 12. Reporte de velocidades máximas de reloj

El diseño fue implementado utilizando el reloj principal de 27 MHz disponible en la Tang Nano 9K. Además, se generó un reloj derivado de menor frecuencia para controlar la lectura del teclado y el refrescamiento del display.

| Dominio de Reloj | Frecuencia Objetivo | Frecuencia Máxima ($F_{max}$) | Estado |
| :--- | :---: | :---: | :---: |
| Reloj Principal (`clk_in`) | 27.00 MHz | 126.28 MHz (Hasta 151.86 MHz en mejor caso) | PASS |
| Reloj Derivado (`clk_1khz`) | 27.00 MHz* | 44.65 MHz (Hasta 52.37 MHz en mejor caso) | PASS |

Los resultados de temporización permiten verificar si el diseño cumple con los márgenes necesarios para operar de forma estable en la FPGA. Debido a que la mayor parte del sistema opera con una frecuencia reducida, se espera que el diseño presente un margen amplio frente a violaciones de tiempo.



## 13. Análisis de principales problemas hallados y soluciones aplicadas

Durante el desarrollo del proyecto se identificaron varios problemas relevantes.

### 13.1 Lectura del teclado

Uno de los primeros retos fue lograr una lectura confiable del teclado matricial. Fue necesario revisar el mapeo de filas y columnas, así como la asignación de las teclas especiales A, B, C, D, * y #.

La solución consistió en definir explícitamente los códigos de cada tecla y validar su funcionamiento mediante pruebas individuales.



### 13.2 Orden de los dígitos en pantalla

Durante la integración se observó que el orden interno de los nibbles en display_data podía afectar la interpretación de los números. Para evitar errores, el controlador de display fue ajustado para almacenar los dígitos en formato natural:

CCC5 -> 5
CC15 -> 15
CC58 -> 58

Esto facilitó que m7_calculadora pudiera convertir correctamente el contenido de pantalla a un valor binario.



### 13.3 Sincronización entre m7_calculadora y m8_divisor

Inicialmente se enviaban operandos y la señal valid en el mismo ciclo. Esto podía provocar que el divisor iniciara la operación antes de que los operandos estuvieran completamente estables.

Para resolverlo, se separó el proceso en dos estados:

ST_START_DIV  -> coloca dividend_out y divisor_out
ST_SEND_VALID -> activa div_valid en el siguiente ciclo

Con esto se mejoró la sincronización entre el controlador principal y la unidad divisora.



### 13.4 Captura del resultado

También se identificó la necesidad de esperar la señal done proveniente del divisor antes de capturar el cociente y el residuo. Por ello, se incluyó un estado dedicado a la captura del resultado:

ST_CAPTURE_RESULT

Esto permitió almacenar los resultados en last_quotient y last_remainder, y posteriormente mostrarlos mediante las teclas # y *.



### 13.5 División entre cero

Se agregó una verificación para evitar ejecutar divisiones entre cero. Si el divisor almacenado es cero, el sistema no inicia la operación y carga un mensaje de error en pantalla:

CEEE

Esto evita comportamientos indefinidos y mejora la robustez del sistema.



### 13.6 Casos límite en FPGA

Durante las pruebas físicas se observaron diferencias entre el comportamiento en simulación y el comportamiento en la FPGA para ciertos casos específicos. Algunos casos límite, como 63 / 15, no presentaron un comportamiento completamente estable en la implementación física.

Estas observaciones sugieren oportunidades de mejora en la validación posterior del divisor, la sincronización de señales y el acondicionamiento del flujo de datos entre módulos. Sin embargo, el sistema logró demostrar correctamente la arquitectura general y la funcionalidad principal en múltiples casos de prueba.



## 14. Fotos y videos del proyecto

En esta sección se incluirán evidencias del funcionamiento físico del sistema en la FPGA.
En el siguiente video podemos ver los casos en donde se sobrepase el límite de bits para el divisor y dividendo, cuando se cruza el limite de 63 y 15 bits respectivamente, aparece un mensaje "EEE" que simula el error de capacidad. Este mensaje de error también se puede ver cuando queremos tratar de dividir algo entre 0. También se puede observar casos de división donde se pueden guardar el divisor y dividendo en los botones B y A respectivamente, y con el D se puede ver el cociente y con el asterisco el residuo. 

https://youtu.be/Di4wjMCVWSk



## 15. Conclusiones

El proyecto permitió implementar una unidad de división entera sin signo en una FPGA Tang Nano 9K, integrando lectura de teclado, almacenamiento de operandos, control secuencial, división aritmética y despliegue en displays de 7 segmentos.

La arquitectura modular facilitó el desarrollo y la depuración del sistema, ya que cada bloque cumplió una función específica dentro del flujo general. El módulo m7_calculadora actuó como controlador principal, mientras que m8_divisor ejecutó la operación aritmética mediante un algoritmo secuencial de desplazamiento y resta.

Las simulaciones funcionales demostraron el comportamiento esperado en múltiples casos de prueba, incluyendo operaciones con residuo, divisiones exactas y división entre cero. En la validación física sobre la FPGA, el sistema logró un funcionamiento correcto en distintos casos, aunque también se observaron inconsistencias en algunos escenarios específicos y casos límite.

En general, el proyecto permitió reforzar conceptos clave de diseño lógico digital, tales como máquinas de estados finitos, sincronización de señales, separación modular, protocolos valid/done, eliminación de rebotes y despliegue multiplexado en 7 segmentos. Además, las limitaciones observadas durante la prueba física representan una base clara para futuras mejoras del diseño.



## 16. Referencias

* Material del curso EL-3307 Diseño Lógico I.
* Pong P. Chu, FPGA Prototyping by SystemVerilog Examples.
* Documentación y ejemplos de la FPGA Tang Nano 9K.
* Código y simulaciones desarrolladas durante el proyecto.
