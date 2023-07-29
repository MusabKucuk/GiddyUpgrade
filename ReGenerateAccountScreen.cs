using TMPro;
using UnityEngine;
using UnityEngine.UI;

// ReSharper disable once CheckNamespace

namespace Solana.Unity.SDK.Example
{
    public class ReGenerateAccountScreen : MonoBehaviour
    {
        [SerializeField]
        private TMP_InputField mnemonicTxt;
        [SerializeField]
        private Button generateBtn;
        [SerializeField]
        private Button loadMnemonicsBtn;
        [SerializeField]
        private TMP_InputField passwordInputField;
        [SerializeField]
        private TextMeshProUGUI wrongPasswordTxt;
        [SerializeField]
        private TextMeshProUGUI errorTxt;
        [SerializeField]
        GameObject mainMenu, loginPanel;

        private void OnEnable()
        {
            wrongPasswordTxt.gameObject.SetActive(false);
        }

        private void Start()
        {
            if (generateBtn != null)
            {
                generateBtn.onClick.AddListener(GenerateNewAccount);
            }

            loadMnemonicsBtn.onClick.AddListener(PasteMnemonicsClicked);
        }

        private async void GenerateNewAccount()
        {
            var password = passwordInputField.text;
            var mnemonic = mnemonicTxt.text;

            var account = await Web3.Instance.CreateAccount(mnemonic, password);
            if (account != null)
            {
                mainMenu.SetActive(true);
                loginPanel.SetActive(false);
            }
            else
            {
                errorTxt.text = "Keywords are not in a valid format.";
            }
        }

        private void PasteMnemonicsClicked()
        {
            mnemonicTxt.text = GUIUtility.systemCopyBuffer;
        }

        private void OnDisable()
        {
            errorTxt.text = string.Empty;
            mnemonicTxt.text = string.Empty;
            passwordInputField.text = string.Empty;
        }

        public void OnClose()
        {
            var wallet = GameObject.Find("wallet");
            wallet.SetActive(false);
        }

    }
}
