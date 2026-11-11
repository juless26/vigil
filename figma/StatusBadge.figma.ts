// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=122-2821
// source=Sources/VigilDesignSystem/Components/StatusBadge.swift
// component=StatusBadge
import figma from 'figma'
const instance = figma.selectedInstance

const status = instance.getEnum('Status', {
  'Check now': '.checkNow',
  'Check soon': '.checkSoon',
  'Holding': '.holding',
  'Not holding': '.notHolding',
})

export default {
  example: figma.code`StatusBadge(status: ${status})`,
  imports: ['import VigilDesignSystem'],
  id: 'status-badge',
  metadata: { nestable: true, props: { status } },
}
