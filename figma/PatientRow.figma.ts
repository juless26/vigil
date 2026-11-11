// url=https://www.figma.com/design/DaQDfrgLkMuBt0izEjLIuA/Vigil?node-id=122-2827
// source=Sources/VigilDesignSystem/Components/PatientRow.swift
// component=PatientRow
import figma from 'figma'
const instance = figma.selectedInstance

const name = instance.getString('Name')
const detail = instance.getString('Detail')
const initials = instance.getString('Initials')
const hasPhoto = instance.getBoolean('Photo')

// The row takes the badge's state as a value, so read it from the nested Status Badge.
const badge = instance.findInstance('Status')
let status = '.checkNow'
if (badge && badge.type === 'INSTANCE') {
  status = String(badge.executeTemplate().metadata?.props?.status ?? '.checkNow')
}

export default {
  example: figma.code`PatientRow(
    name: "${name}",
    detail: "${detail}",
    initials: "${initials}",
    status: ${status}${hasPhoto ? ',\n    photo: mother.photo' : ''}
)`,
  imports: ['import VigilDesignSystem'],
  id: 'patient-row',
  metadata: { nestable: true },
}
