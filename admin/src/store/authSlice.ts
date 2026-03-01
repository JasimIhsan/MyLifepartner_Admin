import { createSlice, type PayloadAction } from "@reduxjs/toolkit";

interface AuthState {
   isAuthenticated: boolean;
   isLoading: boolean;
}

const initialState: AuthState = {
   isAuthenticated: false,
   isLoading: true, // Initially true while verifying session
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
      logoutAction: (state) => {
         state.isAuthenticated = false;
         state.isLoading = false;
      },
   },
});

export const { setAuthenticated, setLoading, logoutAction } = authSlice.actions;

export default authSlice.reducer;
