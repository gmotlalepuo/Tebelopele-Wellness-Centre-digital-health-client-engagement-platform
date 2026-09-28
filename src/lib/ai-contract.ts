import {z} from "zod";
export const chatRequestSchema=z.object({conversationId:z.uuid().optional(),message:z.string().trim().min(1).max(2000),idempotencyKey:z.uuid(),humanOnly:z.boolean().optional()});
export const citationSchema=z.object({article_id:z.uuid(),article_version_id:z.uuid(),chunk_id:z.uuid(),title:z.string().max(200).optional(),slug:z.string().regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/).optional()});
export const aiResponseSchema=z.object({answer:z.string().trim().min(1).max(12000),source:z.enum(["verified","verified_ai","live_data","assistant","no_evidence"]),citations:z.array(citationSchema).max(8),requires_human:z.boolean(),reason_code:z.string().max(100).nullable().optional(),model_id:z.string().regex(/^qwen2\.5(?:[-:].+)?$/i),latency_ms:z.number().nonnegative().optional()});
export type AiAnswer=z.infer<typeof aiResponseSchema>;
export function validateCitations(answer:AiAnswer,allowedChunkIds:Set<string>){return answer.citations.every(c=>allowedChunkIds.has(c.chunk_id))&&(!["verified","verified_ai"].includes(answer.source)||answer.citations.length>0)}
const urgentPatterns=[/\b(can't breathe|cannot breathe|difficulty breathing)\b/i,/\b(unconscious|not waking)\b/i,/\b(suicid|kill myself|self harm)\b/i,/\bsevere bleeding\b/i];
export function requiresUrgentHandoff(message:string){return urgentPatterns.some(pattern=>pattern.test(message))}

