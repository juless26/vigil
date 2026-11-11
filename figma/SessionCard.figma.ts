// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=142-2831
// source=Sources/VigilDesignSystem/Components/SessionCard.swift
// component=SessionCard
import figma from 'figma'
const instance = figma.selectedInstance

const state = instance.getEnum('State', {
  'Active': 'active',
  'Ended': 'ended',
})
const label = instance.getString('Label')
const elapsed = instance.getString('Elapsed')
const goal = instance.getString('Goal')
const meta = instance.getString('Meta')

// The card takes the bar's value, so read it from the nested Progress Bar.
const bar = instance.findInstance('Progress Bar')
let progress = '0.4'
if (bar && bar.type === 'INSTANCE') {
  progress = String(bar.executeTemplate().metadata?.props?.value ?? '0.4')
}

export default {
  example: figma.code`SessionCard(
    label: "${label}",
    elapsed: "${elapsed}",
    goal: "${goal}",
    meta: "${meta}",
    progress: ${progress}${state === 'active' ? ',\n    onPause: { },\n    onEnd: { }' : ''}
)`,
  imports: ['import VigilDesignSystem'],
  id: 'session-card',
  metadata: { nestable: true },
}
