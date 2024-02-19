import { Account } from "./account";

export const Header = () => {
  return (
    <div className="mb-3">
      <p>Nani Intents Shell {"[ Version 1.0.0 ]"}</p>
      <p className="mb-2">(c) 2024 Nani Kotoba DAO LLC. All rights reserved.</p>
      <Account />
    </div>
  );
};
