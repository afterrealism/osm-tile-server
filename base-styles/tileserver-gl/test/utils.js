import { expect } from 'chai';

import { allowedScales } from '../src/utils.js';

describe('allowedScales', function () {
  it('rejects retina scales when the server only enables scale 1', function () {
    expect(allowedScales(undefined, 1)).to.equal(1);
    expect(allowedScales('2x', 1)).to.equal(null);
  });
});
