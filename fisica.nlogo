globals [ first_opinion
          second_opinion
          first_palette
          second_palette
          number-of-turtles
          energy
          max_credibility
          div_credibility
        ]

turtles-own[credibility notoriety opinion followed_people followers]


to setup
  clear-all
  reset-ticks
  setup-plots

  set number-of-turtles  square_size * square_size
  let columns floor (sqrt number-of-turtles)
  let rows ceiling (number-of-turtles / columns)
  let x-spacing max-pxcor  / (columns)
  let y-spacing max-pycor / (rows)

  set-default-shape turtles "person"
  set first_opinion 1
  set second_opinion -1
  set first_palette 10
  set second_palette 80
  set max_credibility 1
  set div_credibility 0.2


  let n 0
  let n_col 1
  let n_row 0
  let numero 0

  while [n < number-of-turtles] [
    if n_col > columns [
      set n_col 1
      set n_row n_row + 1
    ]
    create-turtles 1 [
      setxy (n_col  * x-spacing - x-spacing / 2) (n_row * y-spacing + y-spacing / 2)

      set notoriety choose-probability influencer_probability

      set opinion set_opinion first_opinion_percentage
      set credibility random-normal mean_of_credibility div_credibility

      set color set_color credibility opinion

      set followed_people []
      set followers []
    ]

    set n n + 1
    set n_col n_col + 1
  ]

  update-followed
  update_size
  init_energy


end


to go
  update-plot
  tick
  update_opinion
end


to opinion_setup
  ask turtles [
    set opinion set_opinion first_opinion_percentage
    set color set_color credibility opinion
  ]

end

to-report choose-probability [p1]

  let min_influencer 0.3
  let max_influencer 0.5

  let min_norm 0.01
  let max_norm 0.05

  let r random-float 1.00


  if r < p1 [
    report min_influencer + random-float (max_influencer - min_influencer)
  ]

  report min_norm + random-float (max_norm - min_norm)
end

to-report set_opinion [p1]

  let r random-float 1.00

  if r < p1 [
    report second_opinion
  ]

  report first_opinion
end

to-report set_color [cred opin]

  let palette 0

  if opin = first_opinion [
    set palette first_palette
  ]

  if opin = second_opinion [
    set palette second_palette
  ]


  if cred > 0.8 * max_credibility [
    report 2.5 + palette
  ]

  if cred <= 0.8 * max_credibility  and cred > 0.6 * max_credibility  [
    report 4 + palette
  ]

  if cred <= 0.6 * max_credibility  and cred > 0.4 * max_credibility  [
    report 5.5 + palette
  ]

  if cred <= 0.4 * max_credibility and cred > 0.2 * max_credibility  [
    report 7 + palette
  ]

  if cred <= 0.2 * max_credibility [
  report 8.5 + palette

  ]


end

to-report return_follower [prob]
  let r random-float 1.00

  if r < prob [
    report 1
  ]

  report 0
end

to update-followed

  let new_follower 0


  ask turtles [

    let out_turtle_notoriety notoriety
    let id who

    let follower_list []


    ask other turtles [
      let inner_id who
      set new_follower return_follower out_turtle_notoriety

      if new_follower = 1 [
        set followed_people lput [id] of myself followed_people
        set follower_list lput inner_id follower_list
      ]
    ]
    set followers follower_list
  ]
end

to update_size
  ask turtles [
    let n_followers (length followers / number-of-turtles)
    set size n_followers * 3.9 + 0.9
    ;show length followers
  ]

end

to update-plot
  set-current-plot "Sum of Spins Over Time"
  set-current-plot-pen "Sum of Spins"
  let sum-spins sum [opinion] of turtles
  set sum-spins sum-spins / number-of-turtles
  plotxy ticks sum-spins

end

to init_energy
  let new_opinion 0
  set energy 0
  let spin_interaction 0
  let external_mag 0
  ask turtles[
    set new_opinion 0
    set external_mag external_mag + opinion
    let n_neighbors length followed_people
    if n_neighbors != 0 [
      foreach followed_people [id ->
        ask turtle id [
          set new_opinion new_opinion + credibility * opinion / n_neighbors
        ]
      ]
      ;set new_opinion new_opinion + coherence * opinion
      set spin_interaction spin_interaction + opinion * new_opinion
    ]
  ]

  set energy -1 * J * (spin_interaction + h * external_mag)

end

to-report get_delta_H [turtle_id]
  let delta_h 0
  let neighbors_influence 0
  ask turtle turtle_id [
    set neighbors_influence 0
    let n_neighbors length followed_people
    if n_neighbors != 0 [
      foreach followed_people [id ->
        ask turtle id [
          set neighbors_influence neighbors_influence + credibility * opinion
        ]
      ]
      set delta_h 2 * opinion * ( J * neighbors_influence / n_neighbors + h + coherence * opinion)
      ;show neighbors_influence / n_neighbors
    ]
  ]
  report delta_h
end

to update_opinion
  let i random number-of-turtles
  let delta_h get_delta_H i
  let change set_opinion exp(- delta_h * beta)

  if delta_h != 0 [
    if delta_h < 0 or change < 0 [
      ask turtle i[
        set opinion -1 * opinion
        set color set_color credibility opinion
      ]
      init_energy
    ]
  ]




end

to run_simulation
  mag_beta_plot
  mag_h_plot
end

to mag_beta_plot
  let temperatures (range 0 7 0.1)
  let coherences (list 0.5 0.6 0.7 1)
  let labels (list "C1" "C2" "C3" "C4")
  let results []
  let m 0
  let i 0

  foreach coherences [ coher ->
    set coherence coher
    set results []

    foreach temperatures [temperature ->
      set m 0
      set beta temperature
      opinion_setup
      repeat n_rep[
        go
        ;set m m + mean [opinion] of turtles
      ]

      ;set m m / n_rep
      set m mean [opinion] of turtles
      set results lput (list temperature m) results
    ]

    set-current-plot "Magnetization vs Beta"
    set-current-plot-pen (item i labels)

    foreach results [ point ->
      let temp first point
      let mag last point
      plotxy temp mag
    ]
    set i i + 1
  ]
end

to mag_h_plot
  let h_values (range -0.5 0.5 0.05)
  let coherences (list 0.5 0.6 0.7 1)
  let labels (list "C1" "C2" "C3" "C4")
  let results []
  let m 0
  let i 0

  set beta 2.5

  foreach coherences [ coher ->
    set coherence coher
    set results []

    foreach h_values [h_value ->
      set m 0
      set h h_value
      opinion_setup
      repeat n_rep [
        go
        ;set m m + mean [opinion] of turtles
      ]

      ;set m m / n_rep
      set m mean [opinion] of turtles
      set results lput (list h_value m) results
    ]

    set-current-plot "Magnetization vs h"
    set-current-plot-pen (item i labels)

    foreach results [ point ->
      let temp first point
      let mag last point
      plotxy temp mag
    ]
    set i i + 1
  ]
end






@#$#@#$#@
GRAPHICS-WINDOW
15
12
623
621
-1
-1
17.152
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
34
0
34
0
0
1
ticks
30.0

BUTTON
631
399
887
435
setup
setup
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
636
36
875
69
square_size
square_size
0
20
16.0
1
1
NIL
HORIZONTAL

SLIDER
637
87
876
120
influencer_probability
influencer_probability
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
638
136
878
169
mean_of_credibility
mean_of_credibility
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
639
184
879
217
first_opinion_percentage
first_opinion_percentage
0
1
0.0
0.01
1
NIL
HORIZONTAL

BUTTON
635
461
882
494
go / stop
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
634
332
884
365
coherence
coherence
0
1.5
1.0
0.01
1
NIL
HORIZONTAL

SLIDER
635
504
884
537
beta
beta
0
7
2.5
0.1
1
NIL
HORIZONTAL

PLOT
912
47
1324
253
Sum of Spins Over Time
Time
Sum of spins
0.0
500.0
0.0
1.1
true
false
"" ""
PENS
"Sum of Spins" 1.0 0 -5298144 true "" ""

SLIDER
637
233
880
266
J
J
-1
1
0.15
0.01
1
NIL
HORIZONTAL

TEXTBOX
718
12
805
30
Set up Variables
10
0.0
0

SLIDER
634
282
884
315
h
h
-1
1
0.11
0.01
1
NIL
HORIZONTAL

PLOT
912
261
1325
411
Magnetization vs Beta
NIL
NIL
0.0
7.5
0.0
1.1
true
false
"" ""
PENS
"C1" 1.0 0 -13791810 true "" ""
"C2" 1.0 0 -5298144 true "" ""
"C3" 1.0 0 -14439633 true "" ""
"C4" 1.0 0 -16449023 true "" ""

BUTTON
1028
575
1137
608
Run simulation
run_simulation
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
1336
281
1486
299
Coherence = 
10
0.0
0

TEXTBOX
1336
340
1486
358
Coherence = 
10
15.0
1

TEXTBOX
1336
309
1486
327
Coherence =
10
65.0
1

TEXTBOX
1337
373
1487
391
Coherence = 
10
95.0
1

PLOT
912
421
1326
571
Magnetization vs h
NIL
NIL
-0.5
0.5
0.0
1.1
true
false
"" ""
PENS
"C1" 1.0 0 -14454117 true "" ""
"C2" 1.0 0 -5298144 true "" ""
"C3" 1.0 0 -13840069 true "" ""
"C4" 1.0 0 -16449023 true "" ""

SLIDER
1139
575
1231
608
n_rep
n_rep
100
10000
2000.0
100
1
NIL
HORIZONTAL

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
NetLogo 6.4.0
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
