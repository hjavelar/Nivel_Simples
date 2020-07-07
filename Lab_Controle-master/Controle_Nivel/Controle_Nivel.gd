extends Node

# Constantes:
const V_ENT_MAX = 1
const VS_SAI_Y_MAX = 130
const RECT_ALT_MAX = 270
const MAX_NIVEL_POS = 434

# Variáveis:
var crt_on = 0
var auto_on = 0
var altura = 3
var area = 1
var restricao = 2
#var nivel = 0
var vazao_saida = 0

# Variáveis baseadas em objetos: 
onready var Conteudo_nivel = $Planta_Nivel/Planta/Conteudo_Nivel
onready var Vin_Slider = $Controlador/ReferenceRect/Vazao_Entrada_VSlider
onready var SP_Slider = $Controlador/ReferenceRect/SetPoint_VSlider
onready var Nivel_ProgressBar = $Controlador/ReferenceRect/ProgressBar
onready var control_btn_Of_Off = $Controlador/ReferenceRect/btn_On_Off
onready var plant_seleciona = $Planta_Nivel/Planta/Chave_Seletora/btn_seleciona
onready var plant_btn_on_off = $Planta_Nivel/Planta/TextureButton
onready var Vout = $Planta_Nivel/Vazao_saida
onready var MV_pressure_gauge = $Planta_Nivel/Manometro_visor/Manometro_ponteiro

export var nivel = 0 setget setNivel
# Variáveis do Controlador PID:
var I = 0        # Saída do Integrador
var P = 0        # Saída do Proporcional
var D = 0        # Saída do Derivador
var PID = 0      # Saida do PID
var Erro = 0     # Erro atual
var Eant = 0     # Erro anterior
var BP = 70      # Banda Proporcional
var Kp = 100/BP  # Ganho Proporcional
var Ki = 1.0     # Ganho Integral
var Kd = 0       # Ganho Derivativo
var Ta = 0.1     # Intervalo de amostragem ### VERIFICAR COMPATIBILIDADE COM O delta
var cont = 0     # Contador de ciclos [para ajuste automático do SP]

# Variáveis do gráfico
onready var chart_node = get_node("GDCharts")
var timer;

# Called when the node enters the scene tree for the first time.
func _ready():
	init_graph()
	Vin_Slider.value = 0

func init_graph():
	chart_node.set_chart_type(chart_node.CHART_TYPE.LINE_CHART)
	chart_node.MAX_VALUES = 50
	chart_node.initialize(chart_node.LABELS_TO_SHOW.NO_LABEL, {y = Color(255, 0, 0, 0.1), set_point = Color(0, 0, 0, 1)}, 0)
	
	for i in range(50):
		chart_node.create_new_point({
		label = '',
		values = {
			y = 0,
			set_point = 0
		}
	})
	
	timer = Timer.new()
	timer.wait_time = 1
	timer.connect("timeout",self,"_on_timer_timeout") 
	add_child(timer) #to process
	timer.start() #to start

func _on_timer_timeout():
	chart_node.create_new_point({
		label = '',
		values = {
			y = $Controlador/ReferenceRect/ProgressBar.value,
			set_point = $Controlador/ReferenceRect/SetPoint_VSlider.value
		}
	})
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var vazao
	var VS_MAX = sqrt(altura)/restricao
	var DSeg = 10/delta # número de ciclos para contar 10segundos
	
	Ta = delta
	cont += 1
	if (crt_on==1 && auto_on==0 && cont>=DSeg):
		cont = 0
		# altera o SP aleatoriamente (se a planta estiver ligada e no Manual):
		SP_Slider.value = rand_range(0,100)
	
	Erro = SP_Slider.value - Nivel_ProgressBar.value
	if (crt_on && auto_on):  # Ligado no modo automático
		I += Ki*(Erro+Eant)*delta/2.0 # Integral
		# Limita a sída do Integrador:
		if I>100:
			I = 100
		elif I<0:
			I = 0
		P = Kp*Erro                   # Proporcional
		D = Kd*(Erro-Eant)/delta      # Derivativo
		Eant = Erro                   # Atualiza Erro anterior
		PID = P+I+D
		# Limita o PID:
		if PID>100:
			PID = 100
		elif I<0:
			I = 0
		Vin_Slider.value = P+I+D

	# calcula o novo nível:
	vazao_saida = sqrt(nivel)/restricao
	Vout.value = VS_SAI_Y_MAX*vazao_saida/VS_MAX
	MV_pressure_gauge.rotation_degrees =  Vin_Slider.value*0.01*270*crt_on
	vazao = Vin_Slider.value*0.01*V_ENT_MAX*crt_on - vazao_saida
	self.nivel = clamp( nivel + vazao*delta/area, 0, altura)
	Nivel_ProgressBar.value = 100*nivel/altura

func setNivel(value:float):
	nivel = value
	if Conteudo_nivel:
		Conteudo_nivel.region_rect.size.y = MAX_NIVEL_POS*0.91*value/altura # ajuste de 91% para coincidir com 100%


func _on_CheckButton_toggled(button_pressed):
	if button_pressed:
		crt_on = 1
		plant_btn_on_off.pressed = true
		plant_seleciona.rotation_degrees = 90*auto_on
	else:
		crt_on = 0
		plant_btn_on_off.pressed = false
		plant_seleciona.rotation_degrees = 30

func _on_btn_On_Off_toggled(button_pressed):
	if button_pressed:
		crt_on = 1
		control_btn_Of_Off.pressed = true
		plant_seleciona.rotation_degrees = 90*auto_on
	else:
		crt_on = 0
		control_btn_Of_Off.pressed = false
		plant_seleciona.rotation_degrees = 30


func _on_btn_Man_Auto_toggled(button_pressed):
	if button_pressed:
		auto_on = 1 	# modo Automático
		Vin_Slider.editable = false
		SP_Slider.editable = true
		plant_seleciona.rotation_degrees = 60*crt_on+30
	else:
		auto_on = 0 	# modo Manual
		Vin_Slider.editable = true
		SP_Slider.editable = false
		plant_seleciona.rotation_degrees = 0 + (1-crt_on)*30

func _on_TextureButton_toggled(button_pressed):
	if button_pressed:
		crt_on = 1
		control_btn_Of_Off.pressed = true
		plant_seleciona.rotation_degrees = 90*auto_on
	else:
		crt_on = 0
		control_btn_Of_Off.pressed = false
		plant_seleciona.rotation_degrees = 30
