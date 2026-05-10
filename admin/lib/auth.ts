const TOKEN_KEY = 'aiva_admin_token';

export const auth = {
  saveToken(token: string): void {
    if (typeof window !== 'undefined') localStorage.setItem(TOKEN_KEY, token);
  },

  getToken(): string | null {
    if (typeof window === 'undefined') return null;
    return localStorage.getItem(TOKEN_KEY);
  },

  isLoggedIn(): boolean {
    return !!this.getToken();
  },

  logout(): void {
    if (typeof window !== 'undefined') {
      localStorage.removeItem(TOKEN_KEY);
      window.location.href = '/login';
    }
  },
};
