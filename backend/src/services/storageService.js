import crypto from 'node:crypto';

import { env } from '../config/env.js';

function ensureCloudinaryConfigured() {
  if (!env.cloudinaryCloudName || !env.cloudinaryApiKey || !env.cloudinaryApiSecret) {
    throw new Error('Cloudinary storage is not configured.');
  }
}

function buildSignature(params) {
  const payload = Object.entries(params)
    .filter(([, value]) => value !== undefined && value !== null && `${value}`.trim() !== '')
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([key, value]) => `${key}=${value}`)
    .join('&');

  return crypto
    .createHash('sha1')
    .update(`${payload}${env.cloudinaryApiSecret}`)
    .digest('hex');
}

export async function uploadProofImage({
  buffer,
  mimeType,
  originalName,
  userId,
}) {
  ensureCloudinaryConfigured();

  const timestamp = Math.floor(Date.now() / 1000);
  const folder = env.cloudinaryFolder || 'achievement-vault/proofs';
  const publicId = `proof_${userId}_${Date.now()}`;
  const signature = buildSignature({
    folder,
    public_id: publicId,
    timestamp,
  });

  const form = new FormData();
  form.append('file', new Blob([buffer], { type: mimeType }), originalName || `${publicId}.jpg`);
  form.append('api_key', env.cloudinaryApiKey);
  form.append('timestamp', `${timestamp}`);
  form.append('folder', folder);
  form.append('public_id', publicId);
  form.append('signature', signature);

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${env.cloudinaryCloudName}/image/upload`,
    {
      method: 'POST',
      body: form,
    },
  );

  const rawBody = await response.text();
  let decoded;

  try {
    decoded = JSON.parse(rawBody);
  } catch {
    decoded = null;
  }

  if (!response.ok || !decoded?.secure_url) {
    const message = decoded?.error?.message || 'Cloudinary upload failed.';
    throw new Error(message);
  }

  return {
    provider: 'cloudinary',
    url: decoded.secure_url,
    publicId: decoded.public_id,
    width: Number(decoded.width ?? 0),
    height: Number(decoded.height ?? 0),
    bytes: Number(decoded.bytes ?? 0),
    format: decoded.format ?? 'jpg',
  };
}
