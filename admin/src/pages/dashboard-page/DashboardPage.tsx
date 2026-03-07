import { ChartAreaInteractive } from "./(components)/ChartArea";
import { StatusCards } from "./(components)/StatusCards";

const DashboardPage = () => {
   return (
      <>
         <StatusCards />
         <ChartAreaInteractive />
         <h1>Dashboard</h1>
      </>
   );
};

export default DashboardPage;
