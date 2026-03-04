import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

interface AuthState {
   isAuthenticated: boolean;
   isLoading: boolean;
   user: { id: number; username: string; role: string } | null;
}

const initialState: AuthState = {
   isAuthenticated: false,
   isLoading: true, // Initially true while verifying session
   user: null,
};

const authSlice = createSlice({
   name: "auth",
   initialState,
   reducers: {
      setAuthenticated: (state, action: PayloadAction<boolean>) => {
         state.isAuthenticated = action.payload;
      },
      setLoading: (state, action: PayloadAction<boolean>) => {
         state.isLoading = action.payload;
      },
      setUser: (state, action: PayloadAction<{ id: number; username: string; role: string } | null>) => {
         state.user = action.payload;
      },
      logoutAction: (state) => {
         state.isAuthenticated = false;
         state.isLoading = false;
         state.user = null;
      },
   },
});

export const { setAuthenticated, setLoading, setUser, logoutAction } = authSlice.actions;

export default authSlice.reducer;
