"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { Loader2 } from "lucide-react";
import { useForm, type FieldPath } from "react-hook-form";
import { toast } from "sonner";

import { useApi } from "@/components/auth-provider";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { profilePatch, profileSchema, type ProfileForm } from "@/lib/admin-powers";
import { ApiError, editProfile } from "@/lib/api";

const FIELDS: { name: keyof ProfileForm; label: string }[] = [
  { name: "display_name", label: "Display name" },
  { name: "phone", label: "Phone" },
  { name: "company", label: "Company name" },
];

/** Edits name, phone and company with the app's limits. The email cannot be changed here. */
export function EditProfileDialog({
  uid,
  email,
  initial,
  open,
  onOpenChange,
  onSaved,
}: {
  uid: string;
  email: string | null;
  initial: ProfileForm;
  open: boolean;
  onOpenChange: (o: boolean) => void;
  onSaved: () => void;
}) {
  const api = useApi();
  const form = useForm<ProfileForm>({ resolver: zodResolver(profileSchema), values: initial, mode: "onChange" });
  const { errors, isSubmitting } = form.formState;

  async function save(values: ProfileForm) {
    const patch = profilePatch(initial, values);
    if (!Object.keys(patch).length) {
      toast.info("Nothing has changed.");
      return;
    }
    try {
      await editProfile(api, uid, patch);
      toast.success("Profile updated.");
      onSaved();
      onOpenChange(false);
    } catch (e) {
      const err = e instanceof ApiError ? e : null;
      for (const f of err?.fields ?? []) form.setError(f.field as FieldPath<ProfileForm>, { type: "server", message: f.message });
      toast.error(err?.message ?? "Could not update the profile.");
    }
  }

  return (
    <Dialog open={open} onOpenChange={(o) => !isSubmitting && onOpenChange(o)}>
      <DialogContent className="sm:max-w-md">
        <form onSubmit={form.handleSubmit(save)} className="space-y-4">
          <DialogHeader>
            <DialogTitle>Edit profile</DialogTitle>
            <DialogDescription>{email ?? uid}. The email address cannot be changed here. Empty clears a field.</DialogDescription>
          </DialogHeader>
          {FIELDS.map((f) => (
            <div key={f.name} className="space-y-1.5">
              <Label htmlFor={`profile-${f.name}`}>{f.label}</Label>
              <Input id={`profile-${f.name}`} aria-invalid={!!errors[f.name]} {...form.register(f.name)} />
              {errors[f.name] && <p className="text-xs text-destructive">{errors[f.name]?.message}</p>}
            </div>
          ))}
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={isSubmitting}>
              Cancel
            </Button>
            <Button type="submit" disabled={isSubmitting}>
              {isSubmitting && <Loader2 className="animate-spin" />} Save
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
