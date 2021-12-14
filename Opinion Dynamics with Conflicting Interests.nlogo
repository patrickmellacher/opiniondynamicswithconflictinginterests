; TERMS OF USE:
; Copyright (c) 2021 Patrick Mellacher

; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:

; 1.) The above copyright notice and this permission notice shall be included in all
; copies or substantial portions of the Software.

; 2.) Any publication that contains results from this code (or significant portions) must cite the following publication:
; Mellacher, Patrick (2021). Opinion Dynamics Under Conflicting Interests. GSC Discussion Paper No. 28

; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHOR OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

breed [humans human]

extensions [nw]

humans-own
[
  polluter
  belief
  funds
]

globals
[
  number_polluters
  number_non_polluters
  polluters
  non_polluters
  median_voter
  stdv_belief
  humans_sorted_links
  humans_sorted_fixed
  median_voter_history
  stdv_belief_history
  median_voter_mean
  stdv_belief_mean
]

to setup
  clear-all
  ask patches
  [
    set pcolor green
  ]
  if network_type = "random_network"
  [
    nw:generate-random humans links number_agents randomnetwork_chance
    [
      create_agent
    ]
  ]
  if network_type = "watts_strogatz"
  [
    nw:generate-watts-strogatz humans links number_agents neighborhood_size rewire_probability
    [
      create_agent
    ]
  ]

  set humans_sorted_links sort-on [ (-  count my-links)] humans
  set humans_sorted_fixed sort humans

  layout-circle humans 15


  set median_voter_history []
  set stdv_belief_history []

  ask links
  [
    set shape "dashed"
    ;set size 0.1
  ]
  set_pollutors
  set_non_pollutors
  update_statistics
  reset-ticks

end

to go
  update_social_network_beliefs
  conduct_advertisement
  update_outside_information
  update_statistics
  compute_payoffs
  tick
end

to create_agent
  set shape "circle"
    set size 0.5
  set belief min ( list 1 max (list 0 random-normal belief_mean belief_sd))
  set_color
end

to set_pollutors
  set polluters (turtle-set)
  set number_polluters (share_typeA / 100 * number_agents)
  ask up-to-n-of number_polluters humans
  [
    set polluter 1
    set polluters (turtle-set polluters self)
  ]
end

to set_non_pollutors
  set non_polluters (turtle-set)
  set number_non_polluters number_agents - number_polluters
  ask humans with [polluter = 0]
  [
    set non_polluters (turtle-set non_polluters self)
    ;set polluter 0
  ]
end

to update_outside_information
  ask up-to-n-of ((chance_true_belief_typeA) / 100 * number_polluters) polluters
  [
    set belief 1
    set_color
  ]

  ask up-to-n-of ((chance_true_belief_typeB) / 100 * number_non_polluters) non_polluters
  [
    set belief 0
    set_color
  ]
end

to update_social_network_beliefs
  ask humans
  [
    let other_belief 0
    ask one-of link-neighbors
    [
      set other_belief belief
    ]
    set belief belief + (other_belief - belief) * persuasion_parameter
    set_color
  ]
end

to set_color
  set color abs (max (list belief 0.01)  - 1) * 10
end

to update_statistics
  set median_voter median [belief] of humans
  set stdv_belief standard-deviation [belief] of humans

  set median_voter_history fput median_voter median_voter_history
  set stdv_belief_history fput stdv_belief stdv_belief_history

  if length median_voter_history > 500
  [
    set stdv_belief_history but-last stdv_belief_history
    set median_voter_history but-last median_voter_history
  ]


  set median_voter_mean mean median_voter_history
  set stdv_belief_mean mean  stdv_belief_history

end

to compute_payoffs
  ask polluters
  [
    set funds median_voter * payoff_full
  ]
end

to conduct_advertisement

  ask polluters
  [
    let other_belief belief
    let number_advertisement_targets round funds
    set funds funds - number_advertisement_targets
    if advertisement_target = "random"
    [
      ask up-to-n-of number_advertisement_targets humans
      [
        set belief belief + (other_belief - belief) * persuasion_parameter
        set_color
      ]
    ]
    if advertisement_target = "influencer"
    [
      let humans_sorted_links_now humans_sorted_links
      while [number_advertisement_targets > 0 and length humans_sorted_links_now > 0]
      [
        ask first humans_sorted_links_now
        [
          set belief belief + (other_belief - belief) * persuasion_parameter
          set_color
        ]
        set humans_sorted_links_now but-first humans_sorted_links_now
        set number_advertisement_targets number_advertisement_targets - 1
      ]

    ]
    if advertisement_target = "fixed"
    [
      let humans_sorted_fixed_now humans_sorted_fixed
      while [number_advertisement_targets > 0  and length humans_sorted_fixed_now > 0]
      [
        ask first humans_sorted_fixed_now
        [
          set belief belief + (other_belief - belief) * persuasion_parameter
          set_color
        ]
        set humans_sorted_fixed_now but-first humans_sorted_fixed_now
        set number_advertisement_targets number_advertisement_targets - 1
      ]
    ]
    if advertisement_target = "efficient"
    [
      let humans_sorted_efficiency sort-on [ belief ] humans
      while [number_advertisement_targets > 0  and length humans_sorted_efficiency > 0]
      [
        ask first humans_sorted_efficiency
        [
          set belief belief + (other_belief - belief) * persuasion_parameter
          set_color
        ]
        set humans_sorted_efficiency but-first humans_sorted_efficiency
        set number_advertisement_targets number_advertisement_targets - 1
      ]
    ]
  ]
end

to print_agent_positions
  ask humans
  [
    file-print (word who "," polluter "," ticks "," belief)
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
224
49
661
487
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
14
52
77
85
NIL
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

CHOOSER
11
161
153
206
network_type
network_type
"random_network" "watts_strogatz"
0

INPUTBOX
8
236
152
296
randomnetwork_chance
0.1
1
0
Number

INPUTBOX
10
96
152
156
number_agents
100.0
1
0
Number

SLIDER
13
414
155
447
share_typeA
share_typeA
0
100
1.0
1
1
%
HORIZONTAL

INPUTBOX
14
490
92
550
belief_mean
0.0
1
0
Number

INPUTBOX
97
491
156
551
belief_sd
0.0
1
0
Number

SLIDER
5
578
219
611
chance_true_belief_typeA
chance_true_belief_typeA
0
100
100.0
1
1
%
HORIZONTAL

SLIDER
5
618
220
651
chance_true_belief_typeB
chance_true_belief_typeB
0
100
2.0
1
1
%
HORIZONTAL

BUTTON
82
53
145
86
NIL
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
4
681
220
714
persuasion_parameter
persuasion_parameter
0
1
0.05
0.01
1
NIL
HORIZONTAL

MONITOR
240
654
329
699
median_voter
median_voter
17
1
11

PLOT
232
495
432
645
Median Voter
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot median_voter"

INPUTBOX
5
744
86
804
payoff_full
20.0
1
0
Number

CHOOSER
90
744
221
789
advertisement_target
advertisement_target
"random" "influencer" "fixed" "efficient"
0

MONITOR
453
653
527
698
NIL
stdv_belief
17
1
11

PLOT
448
499
648
649
Standard deviation of belief
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot stdv_belief"

INPUTBOX
9
319
116
379
neighborhood_size
5.0
1
0
Number

INPUTBOX
123
319
221
379
rewire_probability
0.1
1
0
Number

TEXTBOX
12
299
162
317
For Watts-Strogatz network:
11
0.0
1

TEXTBOX
13
217
163
235
For a random network:
11
0.0
1

TEXTBOX
13
472
163
490
Distribution of initial beliefs:
11
0.0
1

TEXTBOX
13
560
163
578
Outside information:
11
0.0
1

TEXTBOX
7
663
227
681
Persuasion (communication&advertisement):
11
0.0
1

TEXTBOX
10
728
240
756
Advertisement/Propaganda/Disinformation:
11
0.0
1

TEXTBOX
12
395
214
413
Share of type A agents (e.g. \"polluters\"):
11
0.0
1

TEXTBOX
24
15
610
57
(c) Patrick Mellacher 2021 \nplease cite as: Mellacher, Patrick (2021). Opinion Dynamics Under Conflicting Interests. GSC Discussion Paper No. 28\n
11
0.0
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
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Random network efficient 1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network efficient 2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network efficient 3" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network efficient 4" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="500"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network random 1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network random 2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network random 3" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network random 4" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="500"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network influencer 1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;influencer&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network influencer 2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;influencer&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network influencer 3" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;influencer&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network influencer 4" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;influencer&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="500"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Watts-Strogatz network efficient 1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;watts_strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Watts-Strogatz network efficient 2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;watts_strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Watts-Strogatz network efficient 3" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;watts_strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Watts-Strogatz network efficient 4" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;watts_strogatz&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="persuasion_parameter" first="0.025" step="0.025" last="1"/>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="500"/>
    </enumeratedValueSet>
    <steppedValueSet variable="chance_true_belief_non_polluters" first="0.025" step="0.1" last="15"/>
  </experiment>
  <experiment name="Random network efficient path-dependency" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="8000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="belief_mean" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;influencer&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="persuasion_parameter">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_non_polluters">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="random network spread S curve 1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="49"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="persuasion_parameter">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_non_polluters">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Random network efficient path-dependency 2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="9"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="belief_mean" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;efficient&quot;"/>
      <value value="&quot;random&quot;"/>
      <value value="&quot;influencer&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="persuasion_parameter">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_non_polluters">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="random network spread S curve 2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="49"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.01"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="persuasion_parameter">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_non_polluters">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="random network spread information inequality 1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="49"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="persuasion_parameter">
      <value value="0.025"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_non_polluters">
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="random network spread information inequality 2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50000"/>
    <metric>median_voter</metric>
    <metric>stdv_belief</metric>
    <metric>median_voter_mean</metric>
    <metric>stdv_belief_mean</metric>
    <steppedValueSet variable="random-seed" first="0" step="1" last="49"/>
    <enumeratedValueSet variable="number_agents">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_polluters">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="neighborhood_size">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomnetwork_chance">
      <value value="0.025"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;random_network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_mean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="belief_sd">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="share_polluters">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="advertisement_target">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="persuasion_parameter">
      <value value="0.025"/>
      <value value="0.05"/>
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewire_probability">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="payoff_full">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance_true_belief_non_polluters">
      <value value="0.25"/>
      <value value="1.5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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

dashed
0.0
-0.2 0 0.0 1.0
0.0 1 4.0 4.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
