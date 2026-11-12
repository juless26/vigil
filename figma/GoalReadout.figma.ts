// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=163-4524
// source=Sources/VigilDesignSystem/Components/Watch/GoalReadout.swift
// component=GoalReadout
import figma from 'figma'
const instance = figma.selectedInstance

const percent = instance.getString('Percent')
const minutes = instance.getString('Minutes')

export default {
  example: figma.code`GoalReadout(percent: "${percent}", minutes: "${minutes}")`,
  imports: ['import VigilDesignSystem'],
  id: 'goal-readout',
  metadata: { nestable: true },
}
