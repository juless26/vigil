// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=163-4681
// source=Sources/VigilDesignSystem/Components/Watch/GoalRing.swift
// component=GoalRing
import figma from 'figma'
const instance = figma.selectedInstance

const icon = instance.getEnum('Icon', {
  'Hand heart': '.handHeart',
  'Hand': '.hand',
  'Pause': '.pause',
  'Star': '.star',
})
const progress = instance.getEnum('Progress', {
  '0%': '0.0',
  '5%': '0.05',
  '25%': '0.25',
  '50%': '0.5',
  '75%': '0.75',
  '100%': '1.0',
})

export default {
  example: figma.code`GoalRing(icon: ${icon}, progress: ${progress})`,
  imports: ['import VigilDesignSystem'],
  id: 'goal-ring',
  metadata: { nestable: true },
}
