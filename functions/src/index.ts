import { setGlobalOptions } from "firebase-functions/v2";

import { createSubscription } from "./functions/createSubscription";
import { verifySubscription } from "./functions/verifySubscription";
import { getPremiumStatus } from "./functions/getPremiumStatus";
import { cancelSubscription } from "./functions/cancelSubscription";
import { razorpayWebhook } from "./functions/webhook";
import {createOneTimeOrder} from "./functions/createOneTimeOrder";
import {verifyOneTimePayment} from "./functions/verifyOneTimePayment";
import { generateMeme } from "./functions/generateMeme";
import { generateChat } from "./functions/generateChat";
import { generateChatStream } from "./functions/generateChatStream";
import { generateImage } from "./functions/generateImage";
import { generateImageEdit } from "./functions/generateImageEdit";
import {claimRewardedImageCredit} from "./functions/claimRewardedImageCredit";
import {claimRewardedEnhancementCredit} from "./functions/claimRewardedEnhancementCredit";
import { uploadUserAttachment } from "./functions/uploadUserAttachment";
import {
  startPhotoEnhancement,
  getPhotoEnhancementStatus,
  prepareVideoEnhancementUpload,
  createVideoEnhancement,
  discardVideoEnhancement,
  cancelVideoEnhancement,
  acceptVideoEnhancement,
  getVideoEnhancementStatus,
} from "./functions/topazEnhance";

setGlobalOptions({
  maxInstances: 10,
});

export {
  createSubscription,
  verifySubscription,
  getPremiumStatus,
  cancelSubscription,
  razorpayWebhook,
  createOneTimeOrder,
  verifyOneTimePayment,
  generateMeme,
  generateChat,
  generateChatStream,
  generateImage,
  generateImageEdit,
  claimRewardedImageCredit,
  claimRewardedEnhancementCredit,
  uploadUserAttachment,
  startPhotoEnhancement,
  getPhotoEnhancementStatus,
  prepareVideoEnhancementUpload,
  createVideoEnhancement,
  discardVideoEnhancement,
  cancelVideoEnhancement,
  acceptVideoEnhancement,
  getVideoEnhancementStatus,
};
