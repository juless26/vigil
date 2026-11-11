// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=140-2820
// source=Sources/VigilDesignSystem/Components/ChoiceRow.swift
// component=ChoiceRow
import figma from 'figma'
const instance = figma.selectedInstance

const label = instance.getString('Label')
const selected = instance.getEnum('State', {
  'Selected': 'true',
  'Unselected': 'false',
})

export default {
  example: figma.code`ChoiceRow("${label}", isSelected: ${selected}) {
    // select this answer
}`,
  imports: ['import VigilDesignSystem'],
  id: 'choice-row',
  metadata: { nestable: true },
}
