// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=122-2866
// source=Sources/VigilDesignSystem/Components/VitalRow.swift
// component=VitalRow
import figma from 'figma'
const instance = figma.selectedInstance

const label = instance.getString('Label')
const value = instance.getString('Value')
const unit = instance.getString('Unit')
const meta = instance.getString('Meta')

export default {
  example: figma.code`VitalRow(label: "${label}", value: "${value}", unit: "${unit}", meta: "${meta}")`,
  imports: ['import VigilDesignSystem'],
  id: 'vital-row',
  metadata: { nestable: true },
}
