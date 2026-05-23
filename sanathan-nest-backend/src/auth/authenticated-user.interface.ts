export interface AuthenticatedUser {
  id: string;
  phone?: string | null;
  email?: string | null;
  role?: string;
}

