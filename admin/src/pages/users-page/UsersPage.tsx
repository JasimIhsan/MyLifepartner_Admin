import { UsersTable, type User } from "./(componets)/UsersTable";

const dummyUsers: User[] = [
   {
      id: 1,
      name: "John Doe",
      email: "john@example.com",
      mobileNumber: "+1234567890",
      role: "USER",
      isVerified: true,
      isEmailVerified: true,
      isProfileCompleted: true,
      hasCompletedImageUpload: true,
      selfieUrl: null,
      selfieStatus: "APPROVED",
      createdAt: new Date(),
      updatedAt: new Date(),
   },
   {
      id: 2,
      name: "Jane Smith",
      email: "jane.smith@example.com",
      mobileNumber: "+0987654321",
      role: "ADMIN",
      isVerified: true,
      isEmailVerified: true,
      isProfileCompleted: true,
      hasCompletedImageUpload: true,
      selfieUrl: null,
      selfieStatus: "APPROVED",
      createdAt: new Date(Date.now() - 86400000 * 2),
      updatedAt: new Date(Date.now() - 86400000 * 2),
   },
   {
      id: 3,
      name: "Alice Johnson",
      email: null,
      mobileNumber: "+1122334455",
      role: "USER",
      isVerified: false,
      isEmailVerified: false,
      isProfileCompleted: false,
      hasCompletedImageUpload: false,
      selfieUrl: null,
      selfieStatus: "PENDING",
      createdAt: new Date(Date.now() - 86400000 * 5),
      updatedAt: new Date(Date.now() - 86400000 * 5),
   },
];

const UsersPage = () => {
   return (
      <div className="p-6 space-y-6 flex flex-col w-full">
         <div>
            <h1 className="text-2xl font-bold tracking-tight">Users Management</h1>
            <p className="text-muted-foreground">Manage your users, view their details and statuses.</p>
         </div>
         <UsersTable data={dummyUsers} />
      </div>
   );
};

export default UsersPage;
