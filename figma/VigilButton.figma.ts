// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=122-2826
// source=Sources/VigilDesignSystem/Components/VigilButton.swift
// component=VigilButton
import figma from 'figma'
const instance = figma.selectedInstance

const label = instance.getString('Label')
const style = instance.getEnum('Style', {
  'Filled': '.filled',
  'Tinted': '.tinted',
})
const size = instance.getEnum('Size', {
  'Large': '.large',
  'Medium': '.medium',
})
// Pressed is drawn by the system while a finger is down, so it has no code.
const state = instance.getEnum('State', {
  'Default': 'default',
  'Pressed': 'default',
  'Disabled': 'disabled',
})

export default {
  example: figma.code`VigilButton("${label}", style: ${style}, size: ${size}) {
    // action
}${state === 'disabled' ? '\n.disabled(true)' : ''}`,
  imports: ['import VigilDesignSystem'],
  id: 'vigil-button',
  metadata: { nestable: true, props: { label } },
}
