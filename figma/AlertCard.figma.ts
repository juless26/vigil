// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=122-2865
// source=Sources/VigilDesignSystem/Components/AlertCard.swift
// component=AlertCard
import figma from 'figma'
const instance = figma.selectedInstance

const level = instance.getEnum('Level', {
  'Check now': '.checkNow',
  'Check soon': '.checkSoon',
})
const title = instance.getString('Title')
const message = instance.getString('Body')
const time = instance.getString('Time')

// The card takes each button's label as a value, so read it from the nested Buttons.
const primaryButton = instance.findInstance('Primary Action')
let primaryLabel = ''
if (primaryButton && primaryButton.type === 'INSTANCE') {
  primaryLabel = String(primaryButton.executeTemplate().metadata?.props?.label ?? '')
}
const secondaryButton = instance.findInstance('Secondary Action')
let secondaryLabel = ''
if (secondaryButton && secondaryButton.type === 'INSTANCE') {
  secondaryLabel = String(secondaryButton.executeTemplate().metadata?.props?.label ?? '')
}

export default {
  example: figma.code`AlertCard(
    level: ${level},
    title: "${title}",
    message: "${message}",
    time: "${time}",
    primary: .init("${primaryLabel}") { },
    secondary: .init("${secondaryLabel}") { }
)`,
  imports: ['import VigilDesignSystem'],
  id: 'alert-card',
  metadata: { nestable: true },
}
