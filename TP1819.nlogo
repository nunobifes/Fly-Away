breed [moscas mosca]
breed [ovos ovo]

moscas-own [energia fertilidade esteril]
ovos-own [tempo-restante quantos-gera mutacao] ; EXTRA MUTACAO

to Setup
  clear-all
  setup-patches
  setup-moscas
  reset-ticks
end

to Go
    ask turtles [
    agir
    informar
  ]
  tick
  if fim [stop]
end

to setup-patches
  ask patches [
    ifelse random 100 < p-celulas-alimento [
      set pcolor brown
    ][
      set pcolor green
    ]

  ]
end

to setup-moscas
  ; criar moscas
  let total-moscas (quantidade-moscas + quantidade-moscas-estereis)

  create-moscas total-moscas [
    setxy  random(max-pxcor + 1) random(max-pycor + 1)
    set heading random(360)
    set fertilidade random(101)
    set esteril false
    set energia energia-inicial
    set shape "mosca"
    set size 1.5
    set color blue
  ]

  ; definir numero de moscas estereis
  ask n-of quantidade-moscas-estereis turtles [
    set color red
    set fertilidade 0
    set esteril true
  ]
end

to informar
  if mostrar-energia and breed = moscas [set label energia]
  if mostrar-quantos-gera and breed = ovos [set label quantos-gera]
end

to-report fim
  ifelse not any? turtles [
    ;user-message "Fim de simulacao"
    report true
  ][
    report false
  ]
end

to agir
  ; se for um ovo reduzir o tempo restante ate a sua eclosao
  ifelse breed = ovos [
    set tempo-restante (tempo-restante - 1)
    if tempo-restante = 0 [eclodir]
  ][
    ; caso contrario, assumir que e uma mosca normal e definir a sua percecao normal
    let moscas-percecao moscas-on neighbors4
    let moscas? any? moscas-percecao
    let comida? any? neighbors4 with [pcolor = brown]

    ; adaptar a percecao no caso das moscas estereis
    if esteril [
      set moscas-percecao turtles-on neighbors
      set moscas? any? moscas-percecao
      set comida? false ; dado que estas nao comem
    ]
    ; verificar se existem moscas na percecao
    ifelse moscas? [
      ; existem moscas na percepcao
      if esteril [
        ; verificar se existem mais do que duas estereis no mesmo sitio para fazer a transformacao
        transformar-se-possivel
      ]
      ask moscas-percecao [
        interagir ; myself - quem perceciona
      ]
      if not esteril [
        ; mover para uma das celulas percecionadas
        move-to one-of neighbors4
      ]
    ][
      ; nao existem moscas na percecao
      ifelse comida?[
        ; existe comida na percecao
        comer
      ][
        ;nao existe comida na percecao (ou e uma mosca esteril)
        accao-defeito
      ]
    ]
    ; quick fix here
    set energia (energia - 1)
    if energia < 1 [die]
  ]
end

to interagir
  ; myself - quem perceciona, self - quem e percecionado
  ifelse breed = ovos [
    ; so acontece quando o myself e esteril (por causa do turtles-on vs moscas-on)
    ifelse mutacoes and tipo-mutacao = "acumulativa" [
      set mutacao (mutacao + 1)
      if mutacao > 100 [set mutacao 100]
    ][
      set quantos-gera (quantos-gera - 1)
      if quantos-gera < 1 [die]
    ]
  ][
    if myself = nobody [stop] ; no caso de ter morrido devido a uma interacao anterior
    ifelse not [esteril] of myself and not esteril [
      ; Mosca + Mosca
      let num-a-gerar floor (([fertilidade] of myself + fertilidade) / 20)
      ; para impedir criar ovos vazios
      if num-a-gerar > 0 [
        gerar-ovo num-a-gerar

        if ovos-custam-energia [ ; EXTRA OVOS
          set energia floor (energia / 2) ; pode ficar com zero de energia
          if energia < 1 [die]
          ask myself [
            set energia floor (energia / 2)  ; pode ficar com zero de energia
            if energia < 1 [die]
          ]
        ]
      ]
    ][
      ifelse [esteril] of myself and esteril [
        ; Esteril + Esteril
        let energia-perceciona [energia] of myself
        let energia-percecionado energia
        ; verificar se algum dos niveis de energia e inferior a 10% da energia inicial
        ifelse energia-perceciona < energia-percecionado [
          ; quem perceciona pode ser eliminado?
          if energia-perceciona < (0.1 * energia-inicial) [
            ; eliminar o que perceciona
            ; e necessario acrescentar energia ao percecionado
            let energia-ganha [energia] of myself
            set energia (energia + energia-ganha)
            ask myself [die]
          ]
        ]
        [
          ifelse energia-perceciona > energia-percecionado [
            ; quem e percecionado pode ser eliminado?
            if energia-percecionado < (0.1 * energia-inicial) [
              ; eliminar quem e percecionado
              ; e necessario acrescentar energia ao que perceciona
              let energia-ganha energia
              ask myself [set energia (energia + energia-ganha)]
              die
            ]
          ][
            ; nenhum pode ser eliminado, e agora?
            accao-defeito
          ]
        ]
      ][
        ifelse [esteril] of myself and not esteril [
          ; Esteril + Mosca
          set fertilidade (fertilidade - ( fertilidade * reducao-fertilidade / 100))
        ][
          ; Mosca + Esteril
          ask myself [set fertilidade (fertilidade - ( fertilidade * reducao-fertilidade / 100))]
        ]
      ]
    ]
  ]

end

to comer
  let comida one-of neighbors4 with [pcolor = brown]
  face comida
  move-to comida
  set energia (energia + energia-obtida-alimento)
  ask comida [set pcolor green]
end

to transformar-se-possivel
  ; verificar se existem mais do que duas estereis no mesmo sitio para fazer a transformacao
  if count (moscas-on patch-here) with [esteril] > 2 [
    ; watch-me
    ; criar a variavel para estar disponivel no proximo scope
    let energia-ganha 1
    ; existe, necessito de verificar se ha alguma mosca normal para obter a mesma energia desta
    let alguma-mosca? any? (moscas-on neighbors) with [not esteril]
    if alguma-mosca? [
      ; obter o valor mais alto de energia entre estas
      set energia-ganha (max [energia] of ((moscas-on neighbors) with [not esteril]))
    ]
    set esteril false
    set energia energia-ganha
    set fertilidade random(101) ; talvez nao?
    set color blue
  ]
end

to gerar-ovo [num-a-gerar]
  hatch-ovos 1 [
    setxy xcor ycor
    set shape "egg"
    set color yellow
    set quantos-gera num-a-gerar
    set tempo-restante tempo-para-eclosao
    if mutacoes and (tipo-mutacao = "acumulativa") [
      set mutacao 0 ; EXTRA MUTACAO
    ]
  ]
end

to eclodir
  hatch-moscas quantos-gera [
    setxy xcor ycor
    set heading random(360)
    set energia energia-inicial
    set shape "mosca"
    set size 1.5
    set fertilidade random(101)
    set esteril false
    set color blue

    if [mutacoes] of myself [
      ifelse tipo-mutacao = "espontanea"[
        ; tipo espontanea
        if random (100) + 1 <= p-mutacao [
          mutar
        ]
      ][
        ; tipo acumulativo
        if random(101) <= [mutacao] of myself [
          mutar
        ]
      ]
    ]
  ]
  die
end

to mutar
  ifelse random(101) <= p-mutacao-fatal [
    die
  ][
    set fertilidade 0
    set esteril true
    set color red
  ]
end

to accao-defeito
  ifelse esteril [
    ; verificar se a percecao da mosca esteril esta vazia
    let percecao-vazia? not any? turtles-on neighbors
    ; se estiver, mover a mosca para a esquerda ou direita
    ifelse percecao-vazia? [
      ifelse random(2) = 0 [right 90][left 90]
      forward 1
    ][
      ; a percecao da mosca esteril nao esta vazia
      let destino no-patches ; inicializar para poder usar nos scopes dos 'ifelses'
      ; qual o numero maximo de moscas na percecao
      let max-moscas max-one-of neighbors [count turtles-here with [breed = moscas and esteril]]
      ; qual o numero maximo de ovos na percecao
      let max-ovos max-one-of neighbors [count turtles-here with [breed = ovos]]
      ; definir o destino como sendo o patch com mais moscas ou ovos
      ifelse max-moscas > max-ovos[
        set destino max-moscas
      ][
        set destino max-ovos
      ]
      face destino
      move-to destino
    ]
  ][
    ; Acao defeito p/ mosca normal
    ; verificar se a percecao esta vazia
    let percecao-vazia? not any? turtles-on neighbors4
    ifelse percecao-vazia? [
      ; esta vazia, logo vou mover a mosca para um patch vazio
      let destino one-of neighbors4 with [not any? turtles-here]
      face destino
      move-to destino
    ][
      ; existem outras moscas na percecao da mosca
      ; mover a mosca para a esquerda ou direita
      ifelse random(2)  = 0 [right 90][left 90]
      forward 1
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
31
27
657
654
-1
-1
12.12
1
10
1
1
1
0
1
1
1
0
50
0
50
0
0
1
ticks
30.0

SLIDER
839
26
994
59
p-celulas-alimento
p-celulas-alimento
5
20
5.0
1
1
%
HORIZONTAL

SLIDER
839
92
994
125
energia-obtida-alimento
energia-obtida-alimento
1
50
20.0
1
1
U
HORIZONTAL

INPUTBOX
669
26
811
86
quantidade-moscas
4.0
1
0
Number

INPUTBOX
669
85
811
145
quantidade-moscas-estereis
20.0
1
0
Number

INPUTBOX
669
145
811
205
tempo-para-eclosao
100.0
1
0
Number

BUTTON
767
302
822
368
Iniciar
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
676
302
768
335
Setup
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
839
59
994
92
reducao-fertilidade
reducao-fertilidade
0
10
10.0
1
1
%
HORIZONTAL

INPUTBOX
669
205
811
265
energia-inicial
5000.0
1
0
Number

SWITCH
841
154
995
187
mostrar-energia
mostrar-energia
1
1
-1000

SWITCH
841
187
995
220
mostrar-quantos-gera
mostrar-quantos-gera
1
1
-1000

TEXTBOX
904
133
940
151
Labels
11
0.0
1

TEXTBOX
694
10
793
28
Definições Principais\n
11
0.0
1

TEXTBOX
871
10
968
28
Outras Definições
11
0.0
1

MONITOR
1071
468
1163
513
Total de Moscas
count moscas
17
1
11

MONITOR
1071
513
1128
558
Moscas
count moscas with [not esteril]
17
1
11

MONITOR
1128
513
1220
558
Moscas Estereis
count moscas with [esteril]
17
1
11

MONITOR
1163
468
1220
513
Ovos
count ovos
17
1
11

PLOT
668
417
1028
656
População
ticks
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"moscas" 1.0 0 -13345367 true "" "plot count moscas with [not esteril]"
"moscas-estereis" 1.0 0 -2674135 true "" "plot count moscas with [esteril]"
"ovos" 1.0 0 -1184463 true "" "plot count ovos"
"comida" 1.0 0 -6459832 true "" "plot count patches with [pcolor = brown]"

TEXTBOX
1138
10
1175
28
Extras
11
0.0
1

SLIDER
1208
135
1338
168
p-mutacao
p-mutacao
1
100
98.0
1
1
%
HORIZONTAL

CHOOSER
1208
90
1338
135
tipo-mutacao
tipo-mutacao
"espontanea" "acumulativa"
0

SWITCH
1208
57
1338
90
mutacoes
mutacoes
1
1
-1000

SLIDER
1208
168
1338
201
p-mutacao-fatal
p-mutacao-fatal
0
100
100.0
1
1
%
HORIZONTAL

BUTTON
676
335
767
368
Step
Go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1044
50
1194
232
A mutação espontânea acontece sempre que um ovo eclode.\n\nA mutacao acumulativa substitui o procedimento de redução do número de moscas que um ovo gera por um procedimento onde um ovo aumenta a probabilidade de sofrer uma mutação sempre que uma mosca esteril interage com este.
11
0.0
1

TEXTBOX
1045
34
1106
52
MUTAÇÃO
12
53.0
1

TEXTBOX
1046
266
1196
308
Diminui a energia de ambos os intervenientes em metade sempre que um ovo é gerado.
11
0.0
1

SWITCH
1206
269
1354
302
ovos-custam-energia
ovos-custam-energia
1
1
-1000

TEXTBOX
1047
249
1197
267
CUSTO P/ OVO
12
53.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

egg
false
0
Circle -7500403 true true 96 76 108
Circle -7500403 true true 72 104 156
Polygon -7500403 true true 221 149 195 101 106 99 80 148

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

mosca
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30
Polygon -1 true false 150 165 210 120 255 105 270 150 240 210 180 195 150 165 90 120 45 105 30 150 60 210 120 195

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
