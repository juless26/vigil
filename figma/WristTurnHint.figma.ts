// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=163-4518
// source=Sources/VigilDesignSystem/Components/Watch/WristTurnHint.swift
// component=WristTurnHint
import figma from 'figma'
const instance = figma.selectedInstance

const alert = instance.getEnum('Alert', {
  'Vibration': '.vibration',
  'Strong vibration': '.strongVibration',
})

export default {
  example: figma.code`WristTurnHint(alert: ${alert})`,
  imports: ['import VigilDesignSystem'],
  id: 'wrist-turn-hint',
  metadata: { nestable: true },
}
