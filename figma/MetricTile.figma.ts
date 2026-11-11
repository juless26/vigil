// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=122-2873
// source=Sources/VigilDesignSystem/Components/MetricTile.swift
// component=MetricTile
import figma from 'figma'
const instance = figma.selectedInstance

const value = instance.getString('Value')
const label = instance.getString('Label')

export default {
  example: figma.code`MetricTile(value: "${value}", label: "${label}")`,
  imports: ['import VigilDesignSystem'],
  id: 'metric-tile',
  metadata: { nestable: true },
}
