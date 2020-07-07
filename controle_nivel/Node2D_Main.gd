extends Node2D

# Constantes:
const V_ENT_MAX = 1
const VS_SAI_Y_MAX = 130
const RECT_ALT_MAX = 270

# Variáveis:
var altura = 3
var area = 1
var restricao = 2
var nivel = 0
var vazao_saida = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Nivel_Rect.rect_size.y = 0
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var vazao
	var VS_MAX = sqrt(altura)/restricao
	var altera_SP = rand_range(0,100)
	
	# altera o SP aleatoriamente:
	if (altera_SP>=50 && altera_SP<=51):
		$SetPoint_VSlider.value = rand_range(0,100)
	
	# calcula o novo nível:
	vazao_saida = sqrt(nivel)/restricao
	$Vazao_Saida.rect_size.y = VS_SAI_Y_MAX*vazao_saida/VS_MAX
	vazao = $Vazao_Entrada_VSlider.value*0.01*V_ENT_MAX - vazao_saida
	nivel = clamp( nivel + vazao*delta/area, 0, altura)
	$Nivel_Rect.rect_size.y = 270*nivel/altura
	$ProgressBar.value = 100*nivel/altura

