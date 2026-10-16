import { z } from "zod";

import type { SendNotificationBody } from "./types";

export const SEND_TITLE_MAX = 120;
export const SEND_MESSAGE_MAX = 1000;
export const SEND_PAYLOAD_MAX = 200;

/** Send form, with the limits of POST /admin/notifications/send. */
export const sendFormSchema = z
  .object({
    target: z.enum(["user", "all"]),
    uid: z.string(),
    /** Shown in the form only; the server needs the uid. */
    email: z.string(),
    type: z.enum(["info", "success", "warning", "error"]),
    category: z.enum(["", "calibration", "referral", "certificate"]),
    title: z
      .string()
      .trim()
      .min(1, "Enter a title.")
      .max(SEND_TITLE_MAX, `The title can be at most ${SEND_TITLE_MAX} characters.`),
    message: z
      .string()
      .trim()
      .min(1, "Enter the message.")
      .max(SEND_MESSAGE_MAX, `The message can be at most ${SEND_MESSAGE_MAX} characters.`),
    action: z.enum(["none", "openResult", "openCalibration", "openCapture", "openHistory", "openPrivacy"]),
    payload: z.string().trim().max(SEND_PAYLOAD_MAX, `The payload can be at most ${SEND_PAYLOAD_MAX} characters.`),
  })
  .superRefine((v, ctx) => {
    if (v.target === "user" && !v.uid) ctx.addIssue({ code: "custom", path: ["email"], message: "Choose a user." });
    if (v.action === "openResult" && !v.payload) {
      ctx.addIssue({ code: "custom", path: ["payload"], message: "Enter the stone ID the result link opens." });
    }
  });

export type SendFormValues = z.infer<typeof sendFormSchema>;

export function sendDefaults(user?: { uid: string; email: string | null } | null): SendFormValues {
  return {
    target: user ? "user" : "all",
    uid: user?.uid ?? "",
    email: user?.email ?? "",
    type: "info",
    category: "",
    title: "",
    message: "",
    action: "none",
    payload: "",
  };
}

export function toSendBody(v: SendFormValues): SendNotificationBody {
  const body: SendNotificationBody = {
    target: v.target,
    type: v.type,
    title: v.title.trim(),
    message: v.message.trim(),
    action: v.action,
  };
  if (v.target === "user") body.uid = v.uid;
  if (v.category) body.category = v.category;
  if (v.payload.trim()) body.payload = v.payload.trim();
  return body;
}
