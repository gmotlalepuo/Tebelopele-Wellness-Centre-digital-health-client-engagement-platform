export const activeAppointmentStatuses=["requested","confirmed"] as const;
export function canCancelAppointment(status:string,startsAt:Date,now=new Date()){return activeAppointmentStatuses.includes(status as (typeof activeAppointmentStatuses)[number])&&startsAt>now}
export function canPublishContent(input:{status:string;processingStatus:string;hasApproval:boolean}){return input.status!=="archived"&&input.processingStatus==="ready"&&input.hasApproval}
