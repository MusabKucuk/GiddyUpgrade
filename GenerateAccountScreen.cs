using codebase.utility;
using Solana.Unity.Wallet.Bip39;
using System;
using TMPro;
using UnityEngine;
using UnityEngine.UI;

// ReSharper disable once CheckNamespace

namespace Solana.Unity.SDK.Example
{
    public class GenerateAccountScreen : MonoBehaviour
    {
        [SerializeField]
        public TextMeshProUGUI mnemonicTxt;
        [SerializeField]
        public Button generateBtn;
        [SerializeField]
        public Button saveMnemonicsBtn;
        [SerializeField]
        public TMP_InputField passwordInputField;
        [SerializeField]
        public TextMeshProUGUI needPasswordTxt;
        [SerializeField]
        GameObject mainMenu, loginPanel, blurImage;


        private void Start()
        {
            mnemonicTxt.text = new Mnemonic(WordList.English, WordCount.TwentyFour).ToString();

            if (generateBtn != null)
            {
                generateBtn.onClick.AddListener(() =>
                {
                    MainThreadDispatcher.Instance().Enqueue(GenerateNewAccount);
                });
            }

            if (saveMnemonicsBtn != null)
            {
                saveMnemonicsBtn.onClick.AddListener(CopyMnemonicsToClipboard);
            }
        }

        private void OnEnable()
        {
            needPasswordTxt.gameObject.SetActive(false);
            blurImage.gameObject.SetActive(true);
            mnemonicTxt.text = new Mnemonic(WordList.English, WordCount.TwentyFour).ToString();
        }

        private async void GenerateNewAccount()
        {
            if (string.IsNullOrEmpty(passwordInputField.text))
            {
                needPasswordTxt.gameObject.SetActive(true);
                needPasswordTxt.text = "Need Password!";
                return;
            }

            var password = passwordInputField.text;
            var mnemonic = mnemonicTxt.text.Trim();
            try
            {
                await Web3.Instance.CreateAccount(mnemonic, password);
                loginPanel.SetActive(false);
                mainMenu.SetActive(true);
                needPasswordTxt.gameObject.SetActive(false);
            }
            catch (Exception ex)
            {
                passwordInputField.gameObject.SetActive(true);
                passwordInputField.text = ex.ToString();
            }
        }

        public void CopyMnemonicsToClipboard()
        {
            Clipboard.Copy(mnemonicTxt.text.Trim());
            gameObject.GetComponent<Toast>()?.ShowToast("Mnemonics copied to clipboard", 3);
            blurImage.gameObject.SetActive(false);

        }

        public void OnClose()
        {
            var wallet = GameObject.Find("wallet");
            wallet.SetActive(false);
        }

    }
}
