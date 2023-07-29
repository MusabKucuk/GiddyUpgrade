import { initializeKeypair } from "./initializeKeypair"
import { Connection, clusterApiUrl, PublicKey, Signer } from "@solana/web3.js"
import {
  Metaplex,
  keypairIdentity,
  bundlrStorage,
  toMetaplexFile,
  NftWithToken,
} from "@metaplex-foundation/js"
import * as fs from "fs"

interface CollectionNftData {
  name: string
  symbol: string
  description: string
  sellerFeeBasisPoints: number
  imageFile: string
  isCollection: boolean
  collectionAuthority: Signer
}

interface NftData {
  name: string
  symbol: string
  description: string
  sellerFeeBasisPoints: number
  imageFile: string
  velocity: string
  durability: string
  stability: string
}

// example data for a new NFT
const nftData = {
  name: "Name",
  symbol: "SYMBOL",
  description: "Description",
  sellerFeeBasisPoints: 0,
  imageFile: "initial.png",
  velocity: '10',
  durability: '10',
  stability: '10'
}

// example data for updating an existing NFT
const updateNftData = {
  name: "Update",
  symbol: "UPDATE",
  description: "Update Description",
  sellerFeeBasisPoints: 100,
  imageFile: "update.png",
  velocity: '20',
  durability: '20',
  stability: '20'
}

async function main() {
  // create a new connection to the cluster's API
  const connection = new Connection(clusterApiUrl("devnet"));

  // initialize a keypair for the user
  const user = await initializeKeypair(connection);

  console.log("PublicKey:", user.publicKey.toBase58());

  // metaplex set up
  const metaplex = Metaplex.make(connection)
      .use(keypairIdentity(user))
      .use(
          bundlrStorage({
              address: "https://devnet.bundlr.network",
              providerUrl: "https://api.devnet.solana.com",
              timeout: 60000,
          }),
  );

  // example data for a new NFT collection
  const collectionNftData = {
    name: "HorseGame Collection",
    symbol: "HGC",
    description: "Collection for HorseGame",
    sellerFeeBasisPoints: 100,
    imageFile: "collection.png",
    isCollection: true,
    collectionAuthority: user,
  }


  // upload data for the collection NFT and get the URI for the metadata
  const collectionUri = await uploadCollectionMetadata(metaplex, collectionNftData)

  // create a collection NFT using the helper function and the URI from the metadata
  const collectionNft = await metaplex.nfts().create(
    {
        uri: collectionUri,
        name: collectionNftData.name,
        sellerFeeBasisPoints: collectionNftData.sellerFeeBasisPoints,
        symbol: collectionNftData.symbol,
        isCollection: true,
    },
    { commitment: "finalized" }
  )

  console.log(
      `Collection Mint: https://explorer.solana.com/address/${collectionNft.mintAddress.toString()}?cluster=devnet`
  )

  // upload the NFT data and get the URI for the metadata
  const uri = await uploadNftMetadata(metaplex, nftData)

  // create an NFT using the helper function and the URI from the metadata
  const nft = await metaplex.nfts().create(
    {
        uri: uri, // metadata URI
        name: nftData.name,
        sellerFeeBasisPoints: nftData.sellerFeeBasisPoints,
        symbol: nftData.symbol,
        collection: collectionNft.mintAddress
    },
    { commitment: "finalized" }
  )

  console.log(
      `Token Mint: https://explorer.solana.com/address/${nft.mintAddress.toString()}?cluster=devnet`,
  )

  //this is what verifies our collection as a Certified Collection
  await metaplex.nfts().verifyCollection(
    {
      mintAddress: nft.mintAddress,
      collectionMintAddress: collectionNft.mintAddress,
      isSizedCollection: true,
    },
    { commitment: "finalized" }
  )

  console.log(
    `Collection NFT:,
    https://explorer.solana.com/address/${collectionNft.mintAddress.toBase58()}/metadata?cluster=devnet`
  )


  // upload updated NFT data and get the new URI for the metadata
  const updatedUri = await uploadNftMetadata(metaplex, updateNftData)

  // update the NFT using the helper function and the new URI from the metadata
  await updateNftUri(metaplex, updatedUri, nft.mintAddress)

  console.log(nft.mintAddress)


}

















async function uploadCollectionMetadata(
  metaplex: Metaplex,
  collectionNftData: CollectionNftData,
): Promise<string> {
  // file to buffer
  const buffer = fs.readFileSync("src/" + collectionNftData.imageFile);

  // buffer to metaplex file
  const file = toMetaplexFile(buffer, collectionNftData.imageFile);

  // upload image and get image uri
  const imageUri = await metaplex.storage().upload(file);
  console.log("image uri:", imageUri);

  // upload metadata and get metadata uri (off chain metadata)
  const { uri } = await metaplex.nfts().uploadMetadata({
    name: collectionNftData.name,
    symbol: collectionNftData.symbol,
    description: collectionNftData.description,
    sellerFeeBasisPoints: collectionNftData.sellerFeeBasisPoints,
    imageFile: collectionNftData.imageFile,
    isCollection: collectionNftData.isCollection,
    collectionAuthority: collectionNftData.collectionAuthority,
  });

  console.log("metadata uri:", uri);
  return uri;
}

// helper function to upload image and metadata
async function uploadNftMetadata(
  metaplex: Metaplex,
  nftData: NftData,
): Promise<string> {
  // file to buffer
  const buffer = fs.readFileSync("src/" + nftData.imageFile);

  // buffer to metaplex file
  const file = toMetaplexFile(buffer, nftData.imageFile);

  // upload image and get image uri
  const imageUri = await metaplex.storage().upload(file);
  console.log("image uri:", imageUri);

  // upload metadata and get metadata uri (off chain metadata)
  const { uri } = await metaplex.nfts().uploadMetadata({
      name: nftData.name,
      symbol: nftData.symbol,
      description: nftData.description,
      image: imageUri,
      attributes: [
        {
          trait_type: 'Velocity',
          value: nftData.velocity
        },
        {
          trait_type: 'Durability',
          value: nftData.durability
        },
        {
          trait_type: 'Stability',
          value: nftData.stability
        },
      ],
  });

  console.log("metadata uri:", uri);
  return uri;
}

// helper function update NFT
async function updateNftUri(
  metaplex: Metaplex,
  uri: string,
  mintAddress: PublicKey,
) {
  // fetch NFT data using mint address
  const nft = await metaplex.nfts().findByMint({ mintAddress });

  // update the NFT metadata
  const { response } = await metaplex.nfts().update(
      {
          nftOrSft: nft,
          uri: uri,
      },
      { commitment: "finalized" },
  );

  console.log(
      `Token Mint: https://explorer.solana.com/address/${nft.address.toString()}?cluster=devnet`,
  );

  console.log(
      `Transaction: https://explorer.solana.com/tx/${response.signature}?cluster=devnet`,
  );
}

main()
  .then(() => {
    console.log("Finished successfully")
    process.exit(0)
  })
  .catch((error) => {
    console.log(error)
    process.exit(1)
  })
