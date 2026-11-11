// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=138-2819
// source=Sources/VigilDesignSystem/Components/PatientAvatar.swift
// component=PatientAvatar
import figma from 'figma'
const instance = figma.selectedInstance

const initials = instance.getString('Initials')
const hasPhoto = instance.getBoolean('Photo')
const size = instance.getEnum('Size', {
  'Small': '44',
  'Medium': '64',
  'Large': '96',
})

export default {
  example: figma.code`PatientAvatar(initials: "${initials}", photo: ${hasPhoto ? 'mother.photo' : 'nil'}, size: ${size})`,
  imports: ['import VigilDesignSystem'],
  id: 'patient-avatar',
  metadata: { nestable: true },
}
