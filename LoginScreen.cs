using Solana.Unity.Wallet;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

// ReSharper disable once CheckNamespace

namespace Solana.Unity.SDK.Example
{
    public class LoginScreen : MonoBehaviour
    {
        [SerializeField]
        private TMP_InputField passwordInputField;
        [SerializeField]
        private TextMeshProUGUI passwordText;
        [SerializeField]
        private Button loginBtn;
        [SerializeField]
        private TextMeshProUGUI messageTxt;
        [SerializeField]
        GameObject mainMenu, loginPanel;

        private void OnEnable()
        {
            passwordInputField.text = string.Empty;

            if (Web3.Wallet != null && Web3.Wallet.Account != null)
            {
                loginPanel.SetActive(false);
                mainMenu.SetActive(true);
            }
        }

        private void Start()
        {
            passwordText.text = "";

            passwordInputField.onSubmit.AddListener(delegate { LoginChecker(); });

            loginBtn.onClick.AddListener(LoginChecker);


            if (messageTxt != null)
                messageTxt.gameObject.SetActive(false);
        }
        private async void LoginChecker()
        {
            var password = passwordInputField.text;
            var account = await Web3.Instance.LoginInGameWallet(password);
            CheckAccount(account);
        }


        private void CheckAccount(Account account)
        {
            if (account != null)
            {
                messageTxt.gameObject.SetActive(false);
                loginPanel.SetActive(false);
                mainMenu.SetActive(true);
            }
            else
            {
                passwordInputField.text = string.Empty;
                messageTxt.gameObject.SetActive(true);
            }
        }

        public void OnClose()
        {
            var wallet = GameObject.Find("wallet");
            wallet.SetActive(false);
        }
    }
}
